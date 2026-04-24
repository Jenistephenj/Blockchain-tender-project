import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:photo_view/photo_view.dart';

class GovernmentViewComplaints extends StatefulWidget {
  final String? currentUserId;
  final String? wardNumber;

  const GovernmentViewComplaints({
    Key? key,
    this.currentUserId,
    this.wardNumber,
  }) : super(key: key);

  @override
  _GovernmentViewComplaintsState createState() => _GovernmentViewComplaintsState();
}

class _GovernmentViewComplaintsState extends State<GovernmentViewComplaints> {
  final DatabaseReference _complaintsRef = FirebaseDatabase.instance.ref('complaints');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');
  final DatabaseReference _departmentsRef = FirebaseDatabase.instance.ref('Department');

  List<Map<String, dynamic>> _allComplaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  Map<String, String?> _userWardCache = {};
  Map<String, Map<String, dynamic>> _userDetailsCache = {};
  Map<String, Map<String, dynamic>> _departmentDetailsCache = {};

  String? _currentGovernmentWard;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';


  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';


  Map<String, bool> _showForwardDialog = {};
  Map<String, TextEditingController> _departmentControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {

    _searchController.dispose();
    _departmentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });


      if (widget.wardNumber != null) {
        _currentGovernmentWard = widget.wardNumber;
        await _fetchComplaints();
      } else {

        await _determineGovernmentWard();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _determineGovernmentWard() async {
    try {
      if (widget.currentUserId != null) {

        final userSnapshot = await _usersRef.child(widget.currentUserId!).once();

        if (userSnapshot.snapshot.exists) {
          final userData = Map<String, dynamic>.from(
              userSnapshot.snapshot.value as Map);
          _currentGovernmentWard = userData['wardno']?.toString();

          if (_currentGovernmentWard != null) {
            await _fetchComplaints();
          } else {

            _currentGovernmentWard = null;
            await _fetchComplaints();
          }
        } else {

          _currentGovernmentWard = null;
          await _fetchComplaints();
        }
      } else {

        _currentGovernmentWard = null;
        await _fetchComplaints();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error determining ward: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchComplaints() async {
    try {
      final complaintsSnapshot = await _complaintsRef.once();

      if (complaintsSnapshot.snapshot.value != null) {
        final rawData = Map<String, dynamic>.from(
            complaintsSnapshot.snapshot.value as Map);

        List<Map<String, dynamic>> tempComplaints = [];

        for (var entry in rawData.entries) {
          final complaintData = Map<String, dynamic>.from(entry.value as Map);
          complaintData['key'] = entry.key;


          final citizenWard = await _getCitizenWard(complaintData['ukey']);


          if (_currentGovernmentWard == null || citizenWard == _currentGovernmentWard) {
            tempComplaints.add(complaintData);


            if (!_showForwardDialog.containsKey(complaintData['key'])) {
              _showForwardDialog[complaintData['key']] = false;
              _departmentControllers[complaintData['key']] = TextEditingController();
            }
          }
        }


        tempComplaints.sort((a, b) {
          final timeA = DateTime.parse(a['timestamp'] ?? '2000-01-01');
          final timeB = DateTime.parse(b['timestamp'] ?? '2000-01-01');
          return timeB.compareTo(timeA);
        });

        setState(() {
          _allComplaints = tempComplaints;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _allComplaints = [];
          _filteredComplaints = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading complaints: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _getCitizenWard(String? citizenUserId) async {
    if (citizenUserId == null) return null;


    if (_userWardCache.containsKey(citizenUserId)) {
      return _userWardCache[citizenUserId];
    }

    try {
      final userSnapshot = await _usersRef.child(citizenUserId).once();

      if (userSnapshot.snapshot.exists) {
        final userData = Map<String, dynamic>.from(
            userSnapshot.snapshot.value as Map);
        final ward = userData['wardno']?.toString();


        _userWardCache[citizenUserId] = ward;
        _userDetailsCache[citizenUserId] = userData;

        return ward;
      }
    } catch (e) {
      print('Error fetching citizen ward: $e');
    }


    _userWardCache[citizenUserId] = null;
    return null;
  }

  Future<Map<String, dynamic>?> _getUserDetails(String? userId) async {
    if (userId == null) return null;


    if (_userDetailsCache.containsKey(userId)) {
      return _userDetailsCache[userId];
    }

    try {
      final userSnapshot = await _usersRef.child(userId).once();

      if (userSnapshot.snapshot.exists) {
        final userData = Map<String, dynamic>.from(
            userSnapshot.snapshot.value as Map);
        _userDetailsCache[userId] = userData;
        return userData;
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> _getDepartmentDetails(String? departmentName) async {
    if (departmentName == null || departmentName.isEmpty) return null;


    if (_departmentDetailsCache.containsKey(departmentName)) {
      return _departmentDetailsCache[departmentName];
    }

    try {
      final departmentsSnapshot = await _departmentsRef.once();

      if (departmentsSnapshot.snapshot.value != null) {
        final rawData = Map<String, dynamic>.from(
            departmentsSnapshot.snapshot.value as Map);

        for (var entry in rawData.entries) {
          final deptData = Map<String, dynamic>.from(entry.value as Map);
          if (deptData['name']?.toString() == departmentName) {
            _departmentDetailsCache[departmentName] = deptData;
            return deptData;
          }
        }
      }
    } catch (e) {
      print('Error fetching department details: $e');
    }

    return null;
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allComplaints);


    if (_selectedFilter != 'All') {
      filtered = filtered.where((complaint) {
        final status = complaint['status']?.toString().toLowerCase() ?? 'pending';
        final filter = _selectedFilter.toLowerCase();

        if (filter == 'pending') {
          return status == 'pending';
        } else if (filter == 'resolved') {
          return status == 'resolved' || status == 'completed';
        } else if (filter == 'forwarded') {
          return status == 'forwarded';
        } else if (filter == 'completed') {
          return status == 'completed';
        }
        return true;
      }).toList();
    }


    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((complaint) {
        final complaintType = complaint['complaintType']?.toString().toLowerCase() ?? '';
        final complaintDesc = complaint['complaint']?.toString().toLowerCase() ?? '';
        final tenderName = complaint['tenderName']?.toString().toLowerCase() ?? '';
        final tenderLoc = complaint['tenderLoc']?.toString().toLowerCase() ?? '';
        final userName = complaint['name']?.toString().toLowerCase() ?? '';
        final priority = complaint['priority']?.toString().toLowerCase() ?? '';
        final completedBy = complaint['completedByDepartment']?.toString().toLowerCase() ?? '';
        final completionNotes = complaint['completionNotes']?.toString().toLowerCase() ?? '';

        return complaintType.contains(query) ||
            complaintDesc.contains(query) ||
            tenderName.contains(query) ||
            tenderLoc.contains(query) ||
            userName.contains(query) ||
            priority.contains(query) ||
            completedBy.contains(query) ||
            completionNotes.contains(query);
      }).toList();
    }

    setState(() {
      _filteredComplaints = filtered;
    });
  }

  Future<void> _updateComplaintStatus(String complaintKey, String newStatus) async {
    try {
      await _complaintsRef.child(complaintKey).update({
        'status': newStatus,
      });

      final index = _allComplaints.indexWhere((c) => c['key'] == complaintKey);
      if (index != -1) {
        setState(() {
          _allComplaints[index]['status'] = newStatus;
          _applyFilters();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint marked as $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _forwardComplaint(Map<String, dynamic> complaint) async {
    final complaintKey = complaint['key'];
    final departmentController = _departmentControllers[complaintKey];

    if (departmentController == null || departmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter department name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {

      final citizenWard = await _getCitizenWard(complaint['ukey']);

      await _complaintsRef.child(complaintKey).update({
        'status': 'forwarded',
        'citizenWard': citizenWard,
        'forwardedTo': departmentController.text.trim(),
        'forwardedDate': DateTime.now().toIso8601String(),
      });


      final index = _allComplaints.indexWhere((c) => c['key'] == complaintKey);
      if (index != -1) {
        setState(() {
          _allComplaints[index]['status'] = 'forwarded';
          _allComplaints[index]['forwardedTo'] = departmentController.text.trim();
          _allComplaints[index]['forwardedDate'] = DateTime.now().toIso8601String();
          _showForwardDialog[complaintKey] = false;
          _applyFilters();
        });
      }


      departmentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint forwarded to ${departmentController.text.trim()}'),
          backgroundColor: Colors.teal[700],
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error forwarding complaint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForwardComplaintDialog(Map<String, dynamic> complaint) {
    final complaintKey = complaint['key'];

    setState(() {
      _showForwardDialog[complaintKey] = true;
    });
  }

  void _cancelForwardComplaint(String complaintKey) {
    setState(() {
      _showForwardDialog[complaintKey] = false;
      _departmentControllers[complaintKey]?.clear();
    });
  }

  Widget _buildForwardComplaintSection(Map<String, dynamic> complaint) {
    final complaintKey = complaint['key'];
    final showDialog = _showForwardDialog[complaintKey] ?? false;
    final controller = _departmentControllers[complaintKey];

    if (showDialog) {
      return Column(
        children: [
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.forward, size: 20, color: Colors.blueGrey[900]),
                    SizedBox(width: 8),
                    Text(
                      'Forward Complaint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  _currentGovernmentWard != null
                      ? 'Ward $_currentGovernmentWard → Department'
                      : 'Forward to Department',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Department Name',
                    hintText: 'e.g., Sanitation, Roads, Water Supply',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _forwardComplaint(complaint),
                        icon: Icon(Icons.send, size: 18),
                        label: Text('Forward Complaint'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[900],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _cancelForwardComplaint(complaintKey),
                      icon: Icon(Icons.cancel, size: 18),
                      label: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  Future<void> _viewImage(String imageUrl, String title) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.teal[700],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown Date';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.teal[700],
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Loading Complaints...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.teal[700],
            ),
          ),
          if (_currentGovernmentWard != null)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Ward: $_currentGovernmentWard',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.teal[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _initializeData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 20),
          Text(
            'No Complaints Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _currentGovernmentWard != null
                ? 'No complaints found for ward $_currentGovernmentWard'
                : 'No complaints available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _initializeData,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[700]!, Colors.teal.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.report_problem,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Citizen Complaints',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _currentGovernmentWard != null
                          ? 'Ward $_currentGovernmentWard'
                          : 'All Wards',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                value: _allComplaints.length.toString(),
                label: 'Total Complaints',
                icon: Icons.receipt,
              ),
              _buildStatCard(
                value: _allComplaints
                    .where((c) => c['status'] == 'pending')
                    .length
                    .toString(),
                label: 'Pending',
                icon: Icons.pending_actions,
              ),
              _buildStatCard(
                value: _allComplaints
                    .where((c) => c['status'] == 'completed')
                    .length
                    .toString(),
                label: 'Completed',
                icon: Icons.check_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String value, required String label, required IconData icon}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [

          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search complaints or department actions...',
                prefixIcon: Icon(Icons.search, color: Colors.teal[700]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),

          SizedBox(height: 12),


          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', Icons.all_inclusive),
                SizedBox(width: 8),
                _buildFilterChip('Pending', Icons.pending_actions),
                SizedBox(width: 8),
                _buildFilterChip('Resolved', Icons.check_circle),
                SizedBox(width: 8),
                _buildFilterChip('Forwarded', Icons.forward),
                SizedBox(width: 8),
                _buildFilterChip('Completed', Icons.verified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.teal[700]),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.teal[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          _applyFilters();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.teal[700],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.teal[700]! : Colors.grey.shade300,
          width: 1,
        ),
      ),
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildCompletedComplaintSection(Map<String, dynamic> complaint) {
    bool hasCompletionProof = complaint['completionProofImage'] != null &&
        (complaint['completionProofImage'] as String).isNotEmpty;
    String completedByDept = complaint['completedByDepartment'] ?? 'Unknown Department';
    String completionNotes = complaint['completionNotes'] ?? 'No completion notes provided';

    return Column(
      children: [
        SizedBox(height: 16),


        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, size: 24, color: Colors.green[700]),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'COMPLETED BY DEPARTMENT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),


              FutureBuilder<Map<String, dynamic>?>(
                future: _getDepartmentDetails(completedByDept),
                builder: (context, snapshot) {
                  final deptData = snapshot.data;
                  final deptWard = deptData?['wardno']?.toString() ?? 'N/A';
                  final deptLocation = deptData?['location']?.toString() ?? 'N/A';
                  final deptMobile = deptData?['mobile']?.toString() ?? 'N/A';

                  return Column(
                    children: [
                      _buildCompletedDetailRow(
                        Icons.business,
                        'Department',
                        completedByDept,
                        Colors.green[700]!,
                      ),
                      SizedBox(height: 8),
                      _buildCompletedDetailRow(
                        Icons.location_on,
                        'Department Ward',
                        deptWard,
                        Colors.blue[700]!,
                      ),
                      SizedBox(height: 8),
                      _buildCompletedDetailRow(
                        Icons.phone,
                        'Contact',
                        deptMobile,
                        Colors.purple[700]!,
                      ),
                      SizedBox(height: 8),
                      _buildCompletedDetailRow(
                        Icons.calendar_today,
                        'Completion Date',
                        _formatDate(complaint['completionDate']),
                        Colors.orange[700]!,
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 12),


              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, size: 18, color: Colors.green[700]),
                      SizedBox(width: 8),
                      Text(
                        'Completion Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      completionNotes,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),


        if (hasCompletionProof)
          Column(
            children: [
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_camera, size: 20, color: Colors.green[700]),
                        SizedBox(width: 8),
                        Text(
                          'COMPLETION PROOF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'VERIFIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    InkWell(
                      onTap: () => _viewImage(complaint['completionProofImage'], 'Completion Proof'),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green[200]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Completion Proof Image',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Verified proof of complaint resolution',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                  if (complaint['completionDate'] != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Verified on: ${_formatDate(complaint['completionDate'])}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.zoom_in,
                              color: Colors.green[700],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCompletedDetailRow(IconData icon, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    bool hasImage = complaint['imageUrl'] != null &&
        (complaint['imageUrl'] as String).isNotEmpty;
    String status = complaint['status'] ?? 'pending';
    String priority = complaint['priority'] ?? 'low';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.teal.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint['complaintType'] ?? 'General Complaint',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          complaint['formattedDate'] ?? 'Unknown Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),


              Text(
                complaint['complaint'] ?? 'No description',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),

              SizedBox(height: 16),


              FutureBuilder<Map<String, dynamic>?>(
                future: _getUserDetails(complaint['ukey']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final userData = snapshot.data;
                  final citizenName = complaint['name'] ?? userData?['name'] ?? 'Unknown';
                  final citizenWard = userData?['wardno']?.toString() ?? 'Not specified';

                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.person,
                          'Citizen',
                          '$citizenName (Ward: $citizenWard)',
                        ),
                        SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.location_on,
                          'Location',
                          complaint['tenderLoc'] ?? 'N/A',
                        ),
                        SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.assignment,
                          'Related Tender',
                          complaint['tenderName'] ?? 'N/A',
                        ),
                      ],
                    ),
                  );
                },
              ),


              if (status == 'completed')
                _buildCompletedComplaintSection(complaint),


              if (status == 'pending')
                _buildForwardComplaintSection(complaint),


              if (status == 'forwarded')
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.forward, size: 20, color: Colors.blueGrey[900]),
                          SizedBox(width: 8),
                          Text(
                            'Forwarded',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'To: ${complaint['forwardedTo'] ?? 'Unknown Department'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      if (complaint['forwardedDate'] != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'On: ${_formatDate(complaint['forwardedDate'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              SizedBox(height: 16),


              if (hasImage)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(),
                    SizedBox(height: 12),
                    Text(
                      'Complaint Image',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _viewImage(complaint['imageUrl'], 'Complaint Image'),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.shade100,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Click to view complaint image',
                                style: TextStyle(
                                  color: Colors.teal[700],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.teal[700],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 16),


              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 'completed'
                          ? Colors.green.shade100
                          : status == 'forwarded'
                          ? Colors.blueGrey[100]
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == 'forwarded'
                          ? 'Forwarded'
                          : status == 'completed'
                          ? 'COMPLETED'
                          : '${status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: status == 'completed'
                            ? Colors.green.shade800
                            : status == 'forwarded'
                            ? Colors.blueGrey[900]
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                  Spacer(),

                  if (status == 'pending')
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showForwardComplaintDialog(complaint),
                          icon: Icon(Icons.forward, size: 18),
                          label: Text('Forward'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _updateComplaintStatus(complaint['key'], 'resolved'),
                          icon: Icon(Icons.check_circle, size: 18),
                          label: Text('Resolve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal[700]),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _buildSearchResultsInfo() {
    if (_searchQuery.isEmpty && _selectedFilter == 'All') {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.teal.shade50,
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: Colors.teal[700]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Showing ${_filteredComplaints.length} of ${_allComplaints.length} complaints'
                  : 'Showing ${_filteredComplaints.length} ${_selectedFilter.toLowerCase()} complaints',
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal[700],
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedFilter = 'All';
                  _applyFilters();
                });
              },
              child: Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.teal[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      body: _isLoading
          ? _buildLoadingState()
          : _hasError
          ? _buildErrorState()
          : Column(
        children: [
          _buildHeader(),
          SizedBox(height: 8),
          _buildSearchAndFilterSection(),
          _buildSearchResultsInfo(),
          _allComplaints.isEmpty
              ? Expanded(child: _buildEmptyState())
              : _filteredComplaints.isEmpty
              ? Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No matching complaints found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filter',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _selectedFilter = 'All';
                        _applyFilters();
                      });
                    },
                    icon: Icon(Icons.clear_all, size: 18),
                    label: Text('Clear Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
              : Expanded(
            child: RefreshIndicator(
              onRefresh: _initializeData,
              color: Colors.teal[700],
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 20),
                itemCount: _filteredComplaints.length,
                itemBuilder: (context, index) {
                  return _buildComplaintCard(_filteredComplaints[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}