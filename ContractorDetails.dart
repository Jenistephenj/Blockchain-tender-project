import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'GovernmentHome.dart';

class ViewAllContractors extends StatefulWidget {
  @override
  _ViewAllContractorsState createState() => _ViewAllContractorsState();
}

class _ViewAllContractorsState extends State<ViewAllContractors> {
  late StreamSubscription<DatabaseEvent> _contractorStreamSubscription;
  final DatabaseReference _contractorRef = FirebaseDatabase.instance.ref('Contractor');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _contractors = {};
  List<MapEntry<String, Map<String, dynamic>>> _filteredContractors = [];

  @override
  void initState() {
    super.initState();
    _setupStreamListener();
  }

  void _setupStreamListener() {
    _contractorStreamSubscription = _contractorRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _updateContractorsData(event);
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _updateContractorsData(DatabaseEvent event) {
    if (event.snapshot.value != null) {
      final rawData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final updatedContractors = <String, Map<String, dynamic>>{};

      rawData.forEach((key, value) {
        updatedContractors[key] = Map<String, dynamic>.from(value);
      });

      _contractors = updatedContractors;
      _applySearchFilter();
    } else {
      _contractors = {};
      _filteredContractors = [];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contractorStreamSubscription.cancel();
    super.dispose();
  }

  void _applySearchFilter() {
    if (_contractors.isEmpty) {
      _filteredContractors = [];
      return;
    }

    final filtered = _contractors.entries.where((entry) {
      final contractor = entry.value;
      final name = (contractor['name'] ?? '').toString().toLowerCase();
      final email = (contractor['email'] ?? '').toString().toLowerCase();
      final location = (contractor['location'] ?? '').toString().toLowerCase();
      final district = (contractor['district'] ?? '').toString().toLowerCase();
      final mobile = (contractor['mobile'] ?? '').toString().toLowerCase();
      final status = (contractor['status'] ?? '').toString().toLowerCase();
      final wardno = (contractor['wardno'] ?? '').toString().toLowerCase();

      final query = searchQuery.toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          location.contains(query) ||
          district.contains(query) ||
          mobile.contains(query) ||
          status.contains(query) ||
          wardno.contains(query);
    }).toList();


    filtered.sort((a, b) {
      final dateA = a.value['registrationDate'] ?? '';
      final dateB = b.value['registrationDate'] ?? '';
      return dateB.compareTo(dateA);
    });

    _filteredContractors = filtered;
  }

  Future<void> _deleteContractor(String contractorId, String email) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this contractor?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'This action will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text('• Remove contractor from database'),
            Text('• Delete authentication account'),
            Text('• Remove all associated data'),
            SizedBox(height: 15),
            Text(
              'This action cannot be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.teal)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(width: 15),
            Text('Deleting contractor...'),
          ],
        ),
        duration: Duration(seconds: 5),
      ),
    );

    try {

      try {
        final user = await _auth.fetchSignInMethodsForEmail(email);
        if (user.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note: Authentication account may still exist. Use Admin panel for complete removal.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        print('Auth check error: $e');
      }


      await _contractorRef.child(contractorId).remove();


      final biddingRef = FirebaseDatabase.instance.ref('bidding');
      final biddingSnapshot = await biddingRef.orderByChild('cKey').equalTo(contractorId).once();
      if (biddingSnapshot.snapshot.value != null) {
        final biddingData = biddingSnapshot.snapshot.value as Map<dynamic, dynamic>;
        for (var key in biddingData.keys) {
          await biddingRef.child(key.toString()).remove();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Contractor deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Error deleting contractor: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callContractor(String phoneNumber) async {
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

  Future<void> _emailContractor(String email) async {
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

  Widget _buildContractorListView() {
    if (_isLoading) {
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
              'Loading Contractors...',
              style: TextStyle(
                color: Colors.teal[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_contractors.isEmpty) {
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
              'No Contractors Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Contractors will appear here once registered',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_filteredContractors.isEmpty) {
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
                    ? 'No Contractors Available'
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
                    ? 'No contractors are registered yet'
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

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: _filteredContractors.length,
      itemBuilder: (context, index) {
        final entry = _filteredContractors[index];
        final contractorId = entry.key;
        final contractor = entry.value;
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
                          Icons.person,
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
                              contractor['name'] ?? 'Unknown Contractor',
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
                              contractor['email'] ?? 'No email',
                              style: TextStyle(
                                color: Colors.teal[700],
                                fontSize: 14,
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
                        Icons.phone,
                        'Mobile',
                        contractor['mobile'] ?? 'N/A',
                        Colors.green,
                        onTap: () => _callContractor(contractor['mobile'] ?? ''),
                      ),
                      _buildDetailCard(
                        Icons.location_on,
                        'Location',
                        contractor['location'] ?? 'N/A',
                        Colors.orange,
                      ),
                      _buildDetailCard(
                        Icons.location_city,
                        'District',
                        contractor['district'] ?? 'N/A',
                        Colors.blue,
                      ),
                      _buildDetailCard(
                        Icons.format_list_numbered,
                        'Ward No',
                        contractor['wardno'] ?? 'N/A',
                        Colors.purple,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.teal[700],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Registration Details',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.teal[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                    _formatDate(contractor['registrationDate'] ?? ''),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.fingerprint, size: 14, color: Colors.teal[800]),
                                  SizedBox(width: 6),
                                  Text(
                                    'ID: ${contractorId.substring(0, 8)}...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal[800],
                                      fontFamily: 'Monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),


                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _emailContractor(contractor['email'] ?? ''),
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
                          onPressed: () => _callContractor(contractor['mobile'] ?? ''),
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
                      SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.shade300, width: 2),
                        ),
                        child: IconButton(
                          onPressed: () => _deleteContractor(contractorId, contractor['email'] ?? ''),
                          icon: Icon(Icons.delete, color: Colors.red),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.all(12),
                          ),
                          tooltip: 'Delete Contractor',
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
    );
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
    });

    _contractorStreamSubscription.cancel();
    _setupStreamListener();
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


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.teal[800]),
                          SizedBox(width: 6),
                          Text(
                            '${_contractors.length} Registered Contractors',
                            style: TextStyle(
                              color: Colors.teal[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.red[800]),
                          SizedBox(width: 6),
                          Text(
                            '⚠️ Admin Delete Enabled',
                            style: TextStyle(
                              color: Colors.red[800],
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


              Expanded(
                child: _buildContractorListView(),
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