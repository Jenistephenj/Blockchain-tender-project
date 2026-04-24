import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'ContracterHome.dart';

class ContractorBiddingStatus extends StatefulWidget {
  @override
  _MyTendeState createState() => _MyTendeState();
}

class _MyTendeState extends State<ContractorBiddingStatus> {
  late StreamController<DatabaseEvent> _biddingStreamController;
  final DatabaseReference _biddingRef =
  FirebaseDatabase.instance.ref('bidding');
  final DatabaseReference _tendersRef =
  FirebaseDatabase.instance.ref('tenders');
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool _isLoading = true;
  late String _currentUserId;
  Map<String, dynamic> _tenderDetailsCache = {};

  @override
  void initState() {
    super.initState();
    final User? user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? '';
    _biddingStreamController = StreamController<DatabaseEvent>();


    _biddingRef.onValue.listen((event) {
      _biddingStreamController.add(event);
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _biddingStreamController.close();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'allot':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'request':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'allot':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      case 'request':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'allot':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending Review';
      case 'request':
        return 'Submitted';
      default:
        return 'Unknown';
    }
  }

  Future<Map<String, dynamic>?> _getTenderDetails(String tenderId) async {
    if (_tenderDetailsCache.containsKey(tenderId)) {
      return _tenderDetailsCache[tenderId];
    }

    try {
      final snapshot = await _tendersRef.child(tenderId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _tenderDetailsCache[tenderId] = data;
        return data;
      }
    } catch (e) {
      print('Error fetching tender details: $e');
    }
    return null;
  }

  Widget _buildBiddingListView() {
    return StreamBuilder<DatabaseEvent>(
      stream: _biddingStreamController.stream,
      builder: (context, snapshot) {
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
                  'Loading Your Bids...',
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
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
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final rawData =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);


          final userBids = rawData.entries.where((entry) {
            final bidData = Map<String, dynamic>.from(entry.value as Map);
            final bidderId = bidData['cKey']?.toString() ?? '';
            final tenderName = (bidData['tenderName'] ?? '').toString().toLowerCase();
            final department = (bidData['department'] ?? '').toString().toLowerCase();
            final status = (bidData['tenderstatus'] ?? '').toString().toLowerCase();

            final query = searchQuery.toLowerCase();
            final matchesSearch = searchQuery.isEmpty ||
                tenderName.contains(query) ||
                department.contains(query) ||
                status.contains(query);

            return bidderId == _currentUserId && matchesSearch;
          }).toList();

          if (userBids.isEmpty) {
            return FadeIn(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 20),
                    Text(
                      searchQuery.isEmpty
                          ? 'No Bids Found'
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
                          ? 'Start bidding on tenders to see them here'
                          : 'Try different search terms',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContracterHome(),
                          ),
                        );
                      },
                      icon: Icon(Icons.search),
                      label: Text('Browse Tenders'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }


          userBids.sort((a, b) {
            final timeA = (a.value as Map)['timestamp'] ?? '';
            final timeB = (b.value as Map)['timestamp'] ?? '';
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: userBids.length,
            itemBuilder: (context, index) {
              final entry = userBids[index];
              final bidId = entry.key;
              final bidData = Map<String, dynamic>.from(entry.value as Map);
              final status = bidData['tenderstatus']?.toString() ?? 'request';
              final statusColor = _getStatusColor(status);
              final isEven = index % 2 == 0;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getTenderDetails(bidData['tenderId'] ?? ''),
                builder: (context, tenderSnapshot) {
                  final tenderData = tenderSnapshot.data;

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(status),
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
                                        bidData['tenderName'] ?? 'Unknown Tender',
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
                                        'Department: ${bidData['department'] ?? 'N/A'}',
                                        style: TextStyle(
                                          color: Colors.teal[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),


                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [

                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.teal[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.currency_rupee,
                                            color: Colors.teal[700],
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Your Bid Amount',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                '₹${bidData['bidAmount'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal[900],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: Colors.grey[200]),

                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.description,
                                            color: Colors.blue[700],
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Tender Details',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                tenderData?['description'] ??
                                                    'No description available',
                                                style: TextStyle(
                                                  fontSize: 14,
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
                                  ),
                                  Divider(height: 1, color: Colors.grey[200]),

                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: Colors.green[700],
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Location',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                tenderData?['location'] ??
                                                    'Location not specified',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: Colors.grey[200]),

                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.calendar_today,
                                            color: Colors.purple[700],
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Submitted On',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                _formatTimestamp(
                                                    bidData['timestamp']),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
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
                            SizedBox(height: 20),


                            if (status == 'rejected')
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.red, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your bid was not selected. Try bidding on other tenders.',
                                        style: TextStyle(
                                          color: Colors.red[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (status == 'Allot')
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.celebration,
                                        color: Colors.green, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Congratulations! Your bid has been approved.',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (status == 'pending' || status == 'request')
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        color: Colors.orange, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your bid is under review. You will be notified once a decision is made.',
                                        style: TextStyle(
                                          color: Colors.orange[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 20),
                Text(
                  'No Bids Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Start bidding on tenders to see them here',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
      },
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'Date not available';
    }
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ContracterHome(),
          ),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'My Bids',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          backgroundColor: Colors.teal[700],
          centerTitle: true,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
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
                          color: Colors.teal[700],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by tender name, department, or status...',
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusLegendItem(
                        'Submitted',
                        Colors.blue,
                        Icons.access_time,
                      ),
                      SizedBox(width: 12),
                      _buildStatusLegendItem(
                        'Pending',
                        Colors.orange,
                        Icons.pending,
                      ),
                      SizedBox(width: 12),
                      _buildStatusLegendItem(
                        'Approved',
                        Colors.green,
                        Icons.check_circle,
                      ),
                      SizedBox(width: 12),
                      _buildStatusLegendItem(
                        'Rejected',
                        Colors.red,
                        Icons.cancel,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),


              Expanded(
                child: _buildBiddingListView(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ContracterHome(),
              ),
            );
          },
          icon: Icon(Icons.home),
          label: Text('Back to Home'),
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusLegendItem(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}