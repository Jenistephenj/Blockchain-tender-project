import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:tender/government/GovernmentHome.dart';

class ViewAllPublicRecords extends StatefulWidget {
  @override
  _ViewAllPublicRecordsState createState() => _ViewAllPublicRecordsState();
}

class _ViewAllPublicRecordsState extends State<ViewAllPublicRecords> {
  late StreamSubscription<DatabaseEvent> _usersStreamSubscription;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');

  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _users = {};
  List<MapEntry<String, Map<String, dynamic>>> _filteredUsers = [];
  String _selectedFilter = 'all';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupStreamListener();
  }

  void _setupStreamListener() {
    _usersStreamSubscription = _usersRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _updateUsersData(event);
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error loading data: $error';
        });
      }
    });
  }

  void _updateUsersData(DatabaseEvent event) {
    try {
      if (event.snapshot.value != null) {
        final rawData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final updatedUsers = <String, Map<String, dynamic>>{};

        rawData.forEach((key, value) {
          updatedUsers[key] = Map<String, dynamic>.from(value);
        });

        _users = updatedUsers;
        _applyFilters();
      } else {
        _users = {};
        _filteredUsers = [];
      }
      _hasError = false;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error processing data: $e';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usersStreamSubscription.cancel();
    super.dispose();
  }

  void _applyFilters() {
    if (_users.isEmpty) {
      _filteredUsers = [];
      return;
    }

    List<MapEntry<String, Map<String, dynamic>>> filtered = _users.entries.toList();


    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((entry) {
        final user = entry.value;
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final mobile = (user['mobile'] ?? '').toString().toLowerCase();
        final location = (user['location'] ?? '').toString().toLowerCase();
        final district = (user['district'] ?? '').toString().toLowerCase();
        final wardno = (user['wardno'] ?? '').toString().toLowerCase();
        final userType = (user['userType'] ?? '').toString().toLowerCase();
        final status = (user['status'] ?? '').toString().toLowerCase();

        final query = searchQuery.toLowerCase();

        return name.contains(query) ||
            email.contains(query) ||
            mobile.contains(query) ||
            location.contains(query) ||
            district.contains(query) ||
            wardno.contains(query) ||
            userType.contains(query) ||
            status.contains(query);
      }).toList();
    }


    if (_selectedFilter == 'citizen') {
      filtered = filtered.where((entry) =>
      (entry.value['userType'] ?? '').toString().toLowerCase() == 'citizen'
      ).toList();
    } else if (_selectedFilter == 'government') {
      filtered = filtered.where((entry) =>
      (entry.value['userType'] ?? '').toString().toLowerCase() == 'government'
      ).toList();
    } else if (_selectedFilter == 'active') {
      filtered = filtered.where((entry) =>
      (entry.value['status'] ?? '').toString().toLowerCase() == 'active'
      ).toList();
    } else if (_selectedFilter == 'pending') {
      filtered = filtered.where((entry) =>
      (entry.value['status'] ?? '').toString().toLowerCase() == 'pending_verification'
      ).toList();
    }


    filtered.sort((a, b) {
      final dateA = a.value['registrationDate'] ?? '';
      final dateB = b.value['registrationDate'] ?? '';
      return dateB.compareTo(dateA);
    });

    _filteredUsers = filtered;
  }

  Future<void> _callUser(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.content_copy, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Phone number copied to clipboard'),
            ],
          ),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Future<void> _emailUser(String email) async {
    final url = 'mailto:$email';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      await Clipboard.setData(ClipboardData(text: email));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.content_copy, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Email copied to clipboard'),
            ],
          ),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusText = 'Active ✓';
        icon = Icons.verified;
        break;
      case 'pending_verification':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        statusText = 'Pending ⏳';
        icon = Icons.access_time;
        break;
      case 'rejected':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        statusText = 'Rejected ✗';
        icon = Icons.cancel;
        break;
      case 'suspended':
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusText = 'Suspended ⚠️';
        icon = Icons.pause_circle;
        break;
      default:
        chipColor = Colors.teal.shade100;
        textColor = Colors.teal.shade800;
        statusText = 'Unknown';
        icon = Icons.help_outline;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: BorderSide.none,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildUserTypeChip(String userType) {
    Color chipColor;
    Color textColor;
    String userTypeText;
    IconData icon;

    switch (userType.toLowerCase()) {
      case 'citizen':
        chipColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        userTypeText = 'Citizen';
        icon = Icons.person;
        break;
      case 'government':
        chipColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        userTypeText = 'Government';
        icon = Icons.account_balance;
        break;
      default:
        chipColor = Colors.purple.shade50;
        textColor = Colors.purple.shade800;
        userTypeText = 'Other';
        icon = Icons.person_outline;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 4),
          Text(
            userTypeText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      side: BorderSide.none,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
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
            'Loading Public Records...',
            style: TextStyle(
              color: Colors.teal[700],
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
            onPressed: _refreshData,
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
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No Public Records Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Public records will appear here once users register',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersListView() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_users.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredUsers.isEmpty) {
      return FadeIn(
        child: Center(
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
                    ? 'No Public Records Available'
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
                    ? 'No users are registered yet'
                    : 'Try different search terms',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }


    final totalUsers = _users.length;
    final citizenCount = _users.values.where((user) =>
    (user['userType'] ?? '').toString().toLowerCase() == 'citizen'
    ).length;
    final govtCount = _users.values.where((user) =>
    (user['userType'] ?? '').toString().toLowerCase() == 'government'
    ).length;
    final activeCount = _users.values.where((user) =>
    (user['status'] ?? '').toString().toLowerCase() == 'active'
    ).length;

    return Column(
      children: [



        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final entry = _filteredUsers[index];
              final userId = entry.key;
              final user = entry.value;
              final isEven = index % 2 == 0;

              return FadeInUp(
                duration: Duration(milliseconds: 300),
                delay: Duration(milliseconds: index * 100),
                child: Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isEven
                          ? [Colors.teal[50]!, Colors.white]
                          : [Colors.blueGrey[50]!, Colors.white],
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
                      color: Colors.teal[100]!,
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
                                color: Colors.teal[900],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                user['userType'] == 'government'
                                    ? Icons.account_balance
                                    : Icons.person,
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
                                    user['name'] ?? 'Unknown User',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[900],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user['email'] ?? 'No email',
                                    style: TextStyle(
                                      color: Colors.teal[700],
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildStatusChip(user['status'] ?? 'pending_verification'),
                                SizedBox(height: 4),
                                _buildUserTypeChip(user['userType'] ?? 'citizen'),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),


                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildDetailCard(
                              Icons.phone,
                              'Mobile',
                              user['mobile'] ?? 'N/A',
                              Colors.green,
                              onTap: () => _callUser(user['mobile'] ?? ''),
                            ),
                            _buildDetailCard(
                              Icons.email,
                              'Email',
                              user['email'] ?? 'N/A',
                              Colors.red,
                              onTap: () => _emailUser(user['email'] ?? ''),
                            ),
                            _buildDetailCard(
                              Icons.location_on,
                              'Location',
                              user['location'] ?? 'N/A',
                              Colors.orange,
                            ),
                            _buildDetailCard(
                              Icons.location_city,
                              'District',
                              user['district'] ?? 'N/A',
                              Colors.blue,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),


                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ward Number',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      user['wardno'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey[300],
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'User ID',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      userId.substring(0, 8) + '...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal[700],
                                        fontFamily: 'Monospace',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),


                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal[100]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.teal[700],
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Registration Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _formatDate(user['registrationDate'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),


                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _emailUser(user['email'] ?? ''),
                                icon: Icon(Icons.email, size: 20),
                                label: Text('Send Email'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _callUser(user['mobile'] ?? ''),
                                icon: Icon(Icons.phone, size: 20),
                                label: Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildDetailCard(IconData icon, String title, String value, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }



  void _refreshData() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _usersStreamSubscription.cancel();
    _setupStreamListener();
  }

  Widget _buildSearchBar() {
    return Padding(
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
                color: Colors.teal[700],
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, mobile, location...',
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
                      _applyFilters();
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
                      _applyFilters();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GovernmentHome(),
          ),
        );
        return true;
      },
      child: Scaffold(

        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.teal[50]!,
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            children: [

              _buildSearchBar(),



              SizedBox(height: 8),


              Expanded(
                child: _buildUsersListView(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _refreshData,
          icon: Icon(Icons.refresh),
          label: Text('Refresh'),
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}