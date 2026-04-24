import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'package:photo_view/photo_view.dart';
import 'package:tender/user/UserHome.dart';

class CompStatus extends StatefulWidget {
  @override
  _CompStatusState createState() => _CompStatusState();
}

class _CompStatusState extends State<CompStatus> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _complaintsRef = FirebaseDatabase.instance.ref('complaints');

  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedFilter = 'all';
  String _currentUserId = '';


  int _totalComplaints = 0;
  int _pendingComplaints = 0;
  int _approvedComplaints = 0;
  int _rejectedComplaints = 0;
  int _completedComplaints = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        await _fetchComplaints();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchComplaints() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final snapshot = await _complaintsRef
          .orderByChild('ukey')
          .equalTo(_currentUserId)
          .once();

      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempComplaints = [];

        data.forEach((key, value) {
          Map<String, dynamic> complaint = Map<String, dynamic>.from(value);
          complaint['complaintId'] = key;
          tempComplaints.add(complaint);
        });


        tempComplaints.sort((a, b) {
          try {
            DateTime dateA = DateTime.parse(a['timestamp'] ?? '');
            DateTime dateB = DateTime.parse(b['timestamp'] ?? '');
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });


        _calculateStatistics(tempComplaints);

        setState(() {
          _complaints = tempComplaints;
          _filteredComplaints = tempComplaints;
          _applyFilter(_selectedFilter);
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading complaints: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics(List<Map<String, dynamic>> complaints) {
    int total = complaints.length;
    int pending = 0;
    int approved = 0;
    int rejected = 0;
    int completed = 0;

    for (var complaint in complaints) {
      String status = (complaint['status'] ?? 'pending').toString().toLowerCase();
      if (status == 'completed') {
        completed++;
      } else if (status == 'approved') {
        approved++;
      } else if (status == 'rejected') {
        rejected++;
      } else {
        pending++;
      }
    }

    setState(() {
      _totalComplaints = total;
      _pendingComplaints = pending;
      _approvedComplaints = approved;
      _rejectedComplaints = rejected;
      _completedComplaints = completed;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;

      if (filter == 'all') {
        _filteredComplaints = List.from(_complaints);
        return;
      }

      _filteredComplaints = _complaints.where((complaint) {
        String status = (complaint['status'] ?? 'pending').toString().toLowerCase();
        return status == filter;
      }).toList();
    });
  }

  Future<void> _viewImage(String imageUrl, {bool isCompletionProof = false}) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(isCompletionProof ? 'Completion Proof' : 'Complaint Proof'),
            backgroundColor: Colors.teal,
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

  String _formatDate(String dateString) {
    try {
      if (dateString.contains('T')) {
        DateTime date = DateTime.parse(dateString);
        return DateFormat('dd MMM yyyy, hh:mm a').format(date);
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        statusText = 'Completed ✓';
        icon = Icons.verified;
        break;
      case 'approved':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusText = 'Approved ✓';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        statusText = 'Rejected ✗';
        icon = Icons.cancel;
        break;
      case 'in_progress':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        statusText = 'In Progress ⚙️';
        icon = Icons.build;
        break;
      default:
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        statusText = 'Pending ⏳';
        icon = Icons.access_time;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.teal,
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
            onPressed: _fetchComplaints,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
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
            Icons.report_problem_outlined,
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
            'You haven\'t submitted any complaints yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => UserHome()),
                    (route) => false,
              );
            },
            icon: Icon(Icons.arrow_back),
            label: Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.teal.shade800],
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.report_problem_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complaint Status',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Track your submitted complaints',
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

        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    List<Map<String, dynamic>> filters = [
      {'label': 'All', 'value': 'all', 'color': Colors.teal},
      {'label': 'Pending', 'value': 'pending', 'color': Colors.blue},
      {'label': 'Approved', 'value': 'approved', 'color': Colors.green},
      {'label': 'Rejected', 'value': 'rejected', 'color': Colors.red},
      {'label': 'Completed', 'value': 'completed', 'color': Colors.purple},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                filter['label'],
                style: TextStyle(
                  color: isSelected ? Colors.white : filter['color'],
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) => _applyFilter(filter['value']),
              backgroundColor: Colors.white,
              selectedColor: filter['color'],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? filter['color'] : Colors.grey.shade300,
                  width: isSelected ? 0 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletionSection(Map<String, dynamic> complaint) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.purple, size: 24),
              SizedBox(width: 8),
              Text(
                'Complaint Resolved',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),


          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Taken by Department:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  complaint['actionTakenByDepartment'] ?? 'No action details provided',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),


          if (complaint['completionNotes'] != null && complaint['completionNotes'].isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completion Notes:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    complaint['completionNotes'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 12),


          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 8,
            children: [
              _buildCompletionDetailItem(
                icon: Icons.domain,
                label: 'Completed By',
                value: complaint['completedByDepartment'] ?? 'N/A',
              ),
              _buildCompletionDetailItem(
                icon: Icons.calendar_today,
                label: 'Completion Date',
                value: _formatDate(complaint['completionDate'] ?? ''),
              ),
              _buildCompletionDetailItem(
                icon: Icons.history,
                label: 'Action Date',
                value: _formatDate(complaint['departmentActionDate'] ?? ''),
              ),
              _buildCompletionDetailItem(
                icon: Icons.forward,
                label: 'Forwarded To',
                value: complaint['forwardedTo'] ?? 'N/A',
              ),
            ],
          ),

          SizedBox(height: 12),


          if (complaint['completionProofImage'] != null && complaint['completionProofImage'].isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion Proof:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: () => _viewImage(complaint['completionProofImage'], isCompletionProof: true),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.photo_camera_back,
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
                                  color: Colors.purple[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap to view resolved proof',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompletionDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.purple),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    bool hasImage = complaint['imageUrl'] != null &&
        (complaint['imageUrl'] as String).isNotEmpty;
    bool isCompleted = (complaint['status'] ?? '').toString().toLowerCase() == 'completed';
    bool hasCompletionProof = complaint['completionProofImage'] != null &&
        (complaint['completionProofImage'] as String).isNotEmpty;

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
              isCompleted ? Colors.purple.shade50 : Colors.teal.shade50,
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
                    child: Text(
                      complaint['tenderName'] ?? 'Unknown Tender',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.purple[800] : Colors.teal[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(complaint['status'] ?? 'pending'),
                ],
              ),

              SizedBox(height: 8),


              Text(
                complaint['complaintType'] ?? 'General Complaint',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 16),


              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  complaint['complaint'] ?? 'No description',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ),

              SizedBox(height: 16),


              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 8,
                children: [
                  _buildDetailItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: complaint['tenderLoc'] ?? 'N/A',
                  ),
                  _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: 'Submitted',
                    value: complaint['formattedDate'] ??
                        _formatDate(complaint['timestamp'] ?? ''),
                  ),
                  _buildDetailItem(
                    icon: Icons.email,
                    label: 'Your Email',
                    value: complaint['email'] ?? 'N/A',
                  ),
                  _buildDetailItem(
                    icon: Icons.person,
                    label: 'Submitted By',
                    value: complaint['name'] ?? 'N/A',
                  ),
                ],
              ),

              SizedBox(height: 16),


              if (hasImage)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(),
                    SizedBox(height: 12),
                    Text(
                      'Complaint Proof',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _viewImage(complaint['imageUrl']),
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
                                color: Colors.teal,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Proof Image',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to view uploaded image',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),


              if (isCompleted)
                _buildCompletionSection(complaint),

              SizedBox(height: 16),


              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fingerprint, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ID: ${complaint['complaintId']?.toString().substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCompleted)
                      Icon(Icons.verified, color: Colors.purple, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
          : _complaints.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildHeader(),
          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: _buildFilterChips(),
          ),
          SizedBox(height: 8),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredComplaints.length} complaint${_filteredComplaints.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    color: Colors.teal[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedFilter != 'all')
                  Text(
                    'Filter: ${_selectedFilter.replaceFirst(_selectedFilter[0], _selectedFilter[0].toUpperCase())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchComplaints,
              color: Colors.teal,
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