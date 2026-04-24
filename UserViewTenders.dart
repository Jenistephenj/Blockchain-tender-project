import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tender/User/UserHome.dart';
import 'package:tender/user/UserViewExpenses.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class viewallotten extends StatefulWidget {
  @override
  _VieweefeTendersState createState() => _VieweefeTendersState();
}

class _VieweefeTendersState extends State<viewallotten> {
  late StreamController<DatabaseEvent> _tenderStreamController;
  final DatabaseReference _tendersRef = FirebaseDatabase.instance.ref('tenders');
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tenderStreamController = StreamController<DatabaseEvent>();
    _tendersRef.onValue.listen((event) {
      _tenderStreamController.add(event);
    });
  }

  @override
  void dispose() {
    _tenderStreamController.close();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.contains('T')) {
        DateTime date = DateTime.parse(dateString);
        return DateFormat('dd MMM yyyy').format(date);
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmount(String amount) {
    try {
      double value = double.tryParse(amount) ?? 0;
      if (value >= 10000000) {
        return '₹${(value / 10000000).toStringAsFixed(1)} Cr';
      } else if (value >= 100000) {
        return '₹${(value / 100000).toStringAsFixed(1)} L';
      } else {
        return '₹${value.toStringAsFixed(2)}';
      }
    } catch (e) {
      return '₹0';
    }
  }

  Future<void> _launchDocument(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open document'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.teal[700]),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by tender name, location or ID...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _isSearching = value.isNotEmpty;
                });
              },
              style: TextStyle(color: Colors.teal[800]),
            ),
          ),
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.teal[700]),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  searchQuery = "";
                  _isSearching = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTenderCard(Map<String, dynamic> itemData, String itemId) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 5,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade50,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.teal[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemData['tenderName'] ?? 'Unknown Tender',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.business, size: 14, color: Colors.teal[700]),
                            SizedBox(width: 5),
                            Text(
                              itemData['department'] ?? 'Unknown Department',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.teal[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 5),
                        Text(
                          'Alloted',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description, size: 18, color: Colors.teal[700]),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          itemData['description'] ?? 'No description available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),


                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    childAspectRatio: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildInfoItem(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: itemData['location'] ?? 'N/A',
                      ),
                      _buildInfoItem(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: _formatDate(itemData['timestamp'] ?? ''),
                      ),
                      _buildInfoItem(
                        icon: Icons.currency_rupee,
                        label: 'Amount',
                        value: _formatAmount(itemData['amount'] ?? '0'),
                        valueColor: Colors.green.shade700,
                      ),
                      _buildInfoItem(
                        icon: Icons.email,
                        label: 'Contact',
                        value: itemData['contactmail'] ?? 'N/A',
                      ),
                    ],
                  ),

                  SizedBox(height: 20),


                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: itemData['documentPath'] != null
                              ? () => _launchDocument(itemData['documentPath'])
                              : null,
                          icon: Icon(Icons.download, size: 20),
                          label: Text('Download Tender'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        width: 60,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserViewExpenses(
                                  tenderId: itemId,
                                  tenderName: itemData['tenderName'],
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.visibility,
                            color: Colors.teal[700],
                            size: 28,
                          ),
                          tooltip: 'View Expenses',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),


                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.fingerprint, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tender ID: $itemId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal[700]),
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
                  color: valueColor ?? Colors.grey[800],
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

  Widget _buildTenderListView() {
    return StreamBuilder<DatabaseEvent>(
      stream: _tenderStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                  'Loading Tenders...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal[700],
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
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Error Loading Tenders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
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

        if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          List<Map<String, dynamic>> filteredTenders = [];

          data.forEach((id, tenderData) {
            Map<String, dynamic> tender = Map<String, dynamic>.from(tenderData);

            // Only show tenders with status 'Allot'
            if (tender['status'] != 'Allot') {
              return;
            }

            // Apply search filter
            bool matchesSearch = searchQuery.isEmpty ||
                (tender['tenderName']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                (tender['location']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                (tender['department']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                (tender['description']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                id.toLowerCase().contains(searchQuery.toLowerCase());

            if (matchesSearch) {
              tender['id'] = id;
              filteredTenders.add(tender);
            }
          });

          // Sort by timestamp (newest first)
          filteredTenders.sort((a, b) {
            try {
              DateTime dateA = DateTime.parse(a['timestamp'] ?? '');
              DateTime dateB = DateTime.parse(b['timestamp'] ?? '');
              return dateB.compareTo(dateA);
            } catch (e) {
              return 0;
            }
          });

          if (filteredTenders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.hourglass_empty,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 20),
                  Text(
                    _isSearching ? 'No matching tenders found' : 'No alloted tenders available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _isSearching
                        ? 'Try a different search term'
                        : 'Check back later for new tenders',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (_isSearching)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          searchQuery = "";
                          _isSearching = false;
                        });
                      },
                      child: Text('Clear Search'),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(bottom: 20),
            itemCount: filteredTenders.length,
            itemBuilder: (context, index) {
              final tender = filteredTenders[index];
              return _buildTenderCard(tender, tender['id']);
            },
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 60, color: Colors.teal[700]),
              SizedBox(height: 20),
              Text(
                'No Tenders Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'There are currently no alloted tenders',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
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
            builder: (context) => UserHome(),
          ),
        );
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.teal[700],
          elevation: 0,
          centerTitle: true,
          title: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min, // 👈 IMPORTANT
              children: [
                Icon(Icons.gavel_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Alloted Tenders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        body: Column(
          children: [
            // Search Bar (below app bar)
            _buildSearchBar(),

            SizedBox(height: 8),

            // Filter Info
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Showing only Alloted Tenders',
                    style: TextStyle(
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  if (_isSearching)
                    Text(
                      '${searchQuery.length > 15 ? searchQuery.substring(0, 15) + '...' : searchQuery}',
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 8),

            // Tender List
            Expanded(
              child: _buildTenderListView(),
            ),
          ],
        ),
      ),
    );
  }
}