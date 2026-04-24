import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:photo_view/photo_view.dart';
import 'DepartmentHome.dart';

class DepartmentCompletedComplaints extends StatefulWidget {


  @override
  _DepartmentCompletedComplaintsState createState() => _DepartmentCompletedComplaintsState();
}

class _DepartmentCompletedComplaintsState extends State<DepartmentCompletedComplaints> {
  final DatabaseReference _complaintsRef = FirebaseDatabase.instance.ref('complaints');
  final DatabaseReference _departmentsRef = FirebaseDatabase.instance.ref('Department');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _allComplaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  String? _departmentName;
  String? _departmentWard;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });


      await _getDepartmentDetails();


      await _fetchCompletedComplaints();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getDepartmentDetails() async {
    try {

      User? user = _auth.currentUser;
      String? userId = user?.uid;

      if (userId != null) {
        final deptSnapshot = await _departmentsRef.child(userId).once();

        if (deptSnapshot.snapshot.exists) {
          final deptData = Map<String, dynamic>.from(
              deptSnapshot.snapshot.value as Map);

          setState(() {
            _departmentName = deptData['name']?.toString();
            _departmentWard = deptData['wardno']?.toString();
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Department details not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Department ID not provided';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error fetching department details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCompletedComplaints() async {
    try {
      final complaintsSnapshot = await _complaintsRef.once();

      if (complaintsSnapshot.snapshot.value != null) {
        final rawData = Map<String, dynamic>.from(
            complaintsSnapshot.snapshot.value as Map);

        List<Map<String, dynamic>> tempComplaints = [];

        for (var entry in rawData.entries) {
          final complaintData = Map<String, dynamic>.from(entry.value as Map);
          complaintData['key'] = entry.key;


          final status = complaintData['status']?.toString();
          final completedByDept = complaintData['completedByDepartment']?.toString();
          final citizenWard = complaintData['citizenWard']?.toString();


          if ((status == 'completed' || status == 'resolved') &&
              (completedByDept == _departmentName || citizenWard == _departmentWard)) {
            tempComplaints.add(complaintData);
          }
        }


        tempComplaints.sort((a, b) {
          final timeA = DateTime.parse(a['completionDate'] ?? a['departmentActionDate'] ?? '2000-01-01');
          final timeB = DateTime.parse(b['completionDate'] ?? b['departmentActionDate'] ?? '2000-01-01');
          return timeB.compareTo(timeA);
        });

        setState(() {
          _allComplaints = tempComplaints;
          _filteredComplaints = tempComplaints;
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
        _errorMessage = 'Error loading completed complaints: $e';
        _isLoading = false;
      });
    }
  }

  void _applySearchFilter() {
    if (searchQuery.isEmpty) {
      setState(() {
        _filteredComplaints = List.from(_allComplaints);
      });
      return;
    }

    final query = searchQuery.toLowerCase();
    setState(() {
      _filteredComplaints = _allComplaints.where((complaint) {
        final complaintText = (complaint['complaint'] ?? '').toString().toLowerCase();
        final complaintType = (complaint['complaintType'] ?? '').toString().toLowerCase();
        final location = (complaint['tenderLoc'] ?? '').toString().toLowerCase();
        final tenderName = (complaint['tenderName'] ?? '').toString().toLowerCase();
        final completionNotes = (complaint['completionNotes'] ?? '').toString().toLowerCase();

        return complaintText.contains(query) ||
            complaintType.contains(query) ||
            location.contains(query) ||
            tenderName.contains(query) ||
            completionNotes.contains(query);
      }).toList();
    });
  }

  Future<void> _viewImage(String imageUrl, String title) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.blueGrey[900],
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
            color: Colors.blueGrey[900],
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Loading Completed Complaints...',
            style: TextStyle(
              color: Colors.blueGrey[800],
              fontSize: 16,
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
            color: Colors.red,
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _initializeData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[900],
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
            Icons.task_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No Completed Complaints',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            _departmentName != null
                ? 'No complaints completed by $_departmentName yet'
                : 'No completed complaints available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _initializeData,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[900],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[900]!, Colors.blueGrey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.task_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _departmentName ?? 'Department',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Completed Complaints with Proofs',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                value: _allComplaints.length.toString(),
                label: 'Total Completed',
                icon: Icons.check_circle,
              ),
              _buildStatCard(
                value: _departmentWard ?? 'N/A',
                label: 'Ward',
                icon: Icons.location_on,
              ),
              _buildStatCard(
                value: _allComplaints
                    .where((c) => c['completionProofImage'] != null)
                    .length
                    .toString(),
                label: 'With Proofs',
                icon: Icons.photo,
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

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    bool hasOriginalImage = complaint['imageUrl'] != null &&
        (complaint['imageUrl'] as String).isNotEmpty;
    bool hasCompletionProof = complaint['completionProofImage'] != null &&
        (complaint['completionProofImage'] as String).isNotEmpty;
    String priority = complaint['priority'] ?? 'low';
    final isEven = _allComplaints.indexOf(complaint) % 2 == 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEven
              ? [Colors.blueGrey[50]!, Colors.white]
              : [Colors.grey[50]!, Colors.white],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.blueGrey[100]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint['complaintType'] ?? 'General Complaint',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[900],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Completed on: ${_formatDate(complaint['completionDate'])}',
                        style: TextStyle(
                          color: Colors.blueGrey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),


            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDetailCard(
                  Icons.person,
                  'Citizen',
                  complaint['name'] ?? 'N/A',
                  Colors.blueGrey,
                ),
                _buildDetailCard(
                  Icons.location_on,
                  'Location',
                  complaint['tenderLoc'] ?? 'N/A',
                  Colors.blueAccent,
                ),
                _buildDetailCard(
                  Icons.assignment,
                  'Related Tender',
                  complaint['tenderName'] ?? 'N/A',
                  Colors.deepOrange,
                ),
                _buildDetailCard(
                  Icons.business,
                  'Completed By',
                  complaint['completedByDepartment'] ?? _departmentName ?? 'N/A',
                  Colors.indigo,
                ),
              ],
            ),
            SizedBox(height: 16),


            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Colors.blueGrey[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Original Complaint',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    complaint['complaint'] ?? 'No description provided',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),


            if (complaint['completionNotes'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            Icon(
                              Icons.notes,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Completion Notes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          complaint['completionNotes'] ?? 'No completion notes provided',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),


            if (hasOriginalImage)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Complaint Image',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () => _viewImage(complaint['imageUrl'], 'Original Complaint Image'),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueGrey[100]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[900],
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
                              'Click to view original complaint image',
                              style: TextStyle(
                                color: Colors.blueGrey[700],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.blueGrey[900],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),


            if (hasCompletionProof)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.photo_camera,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Completion Proof',
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
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PROOF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Visual proof of complaint resolution',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () => _viewImage(complaint['completionProofImage'], 'Completion Proof'),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green[100]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.verified_user,
                              color: Colors.white,
                              size: 24,
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
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Click to view proof of completion',
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 8),


            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.blueGrey[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timeline:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Forwarded: ${_formatDate(complaint['forwardedDate'])} • Completed: ${_formatDate(complaint['completionDate'])}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintListView() {
    if (_filteredComplaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              searchQuery.isEmpty
                  ? 'No Completed Complaints'
                  : 'No results for "$searchQuery"',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              searchQuery.isEmpty
                  ? 'All complaints are successfully resolved'
                  : 'Try different search terms',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: _filteredComplaints.length,
      itemBuilder: (context, index) {
        return _buildComplaintCard(_filteredComplaints[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DepartmentHome(),
          ),
        );
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey[50],
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blueGrey[50]!,
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.blueGrey[900],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by complaint type, notes, or tender name...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                _applySearchFilter();
                              });
                            },
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                                _applySearchFilter();
                              });
                            },
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.green[800]),
                          SizedBox(width: 6),
                          Text(
                            'Showing completed/resolved complaints',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),


              if (!_isLoading && !_hasError && _allComplaints.isNotEmpty)
                _buildHeader(),

              SizedBox(height: 8),


              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasError
                    ? _buildErrorState()
                    : _allComplaints.isEmpty
                    ? _buildEmptyState()
                    : _buildComplaintListView(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _initializeData,
          icon: Icon(Icons.refresh),
          label: Text('Refresh'),
          backgroundColor: Colors.blueGrey[900],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}