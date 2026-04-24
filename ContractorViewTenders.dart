import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'Bidding.dart';
import 'ContracterHome.dart';

class VieTenders extends StatefulWidget {
  @override
  _VieweefeTendersState createState() => _VieweefeTendersState();
}

class _VieweefeTendersState extends State<VieTenders> {
  late StreamController<DatabaseEvent> _tenderStreamController;
  final DatabaseReference _tendersRef = FirebaseDatabase.instance.ref('tenders');
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tenderStreamController = StreamController<DatabaseEvent>();
    _tendersRef.onValue.listen((event) {
      _tenderStreamController.add(event);
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tenderStreamController.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadDocument(String? documentUrl) async {
    if (documentUrl == null || documentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No document available for download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (await canLaunch(documentUrl)) {
        await launch(documentUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.download_done, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Opening document...'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {

      await Clipboard.setData(ClipboardData(text: documentUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.link, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Document link copied to clipboard'),
              ),
            ],
          ),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildTenderListView() {
    return StreamBuilder<DatabaseEvent>(
      stream: _tenderStreamController.stream,
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
                  'Loading Tenders...',
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

          final filteredKeys = rawData.keys.where((key) {
            final item = Map<String, dynamic>.from(rawData[key]);
            final tenderId = key.toLowerCase();
            final location = (item['location'] ?? '').toString().toLowerCase();
            final tenderName = (item['tenderName'] ?? '').toString().toLowerCase();
            final department = (item['department'] ?? '').toString().toLowerCase();
            final status = item['status'] ?? '';

            final query = searchQuery.toLowerCase();
            return (tenderId.contains(query) ||
                location.contains(query) ||
                tenderName.contains(query) ||
                department.contains(query)) &&
                status == 'request';
          }).toList();

          if (filteredKeys.isEmpty) {
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
                          ? 'No Tenders Available'
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
                          ? 'Check back later for new tenders'
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


          filteredKeys.sort((a, b) {
            final itemA = Map<String, dynamic>.from(rawData[a] as Map);
            final itemB = Map<String, dynamic>.from(rawData[b] as Map);
            final timeA = itemA['timestamp'] ?? '';
            final timeB = itemB['timestamp'] ?? '';
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: filteredKeys.length,
            itemBuilder: (context, index) {
              final itemId = filteredKeys[index];
              final itemData = Map<String, dynamic>.from(rawData[itemId] as Map);
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
                                color: Colors.teal[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.business_center,
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
                                    itemData['tenderName'] ?? 'Unnamed Tender',
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
                                    'Department: ${itemData['department'] ?? 'N/A'}',
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


                        _buildDetailSection(itemData),
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
                                    Icons.description,
                                    color: Colors.teal[700],
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                itemData['description'] ?? 'No description provided',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
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
                                onPressed: () => _downloadDocument(itemData['documentPath']),
                                icon: Icon(Icons.download, size: 20),
                                label: Text('Download Document'),
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
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.teal[300]!, width: 2),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BidAmountPage(
                                        tenderId: itemId,
                                        tenderName: itemData['tenderName'],
                                        department: itemData['department'],
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.gavel, color: Colors.teal[700]),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.all(12),
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
                  'No Tenders Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Check back later for new tenders',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDetailSection(Map<String, dynamic> itemData) {
    return Container(
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
                Expanded(
                  child: _buildCompactDetailItem(
                    Icons.email,
                    'Contact',
                    itemData['contactmail'] ?? 'N/A',
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildCompactDetailItem(
                    Icons.location_on,
                    'Location',
                    itemData['location'] ?? 'N/A',
                    Colors.green,
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
                Expanded(
                  child: _buildCompactDetailItem(
                    Icons.currency_rupee,
                    'Amount',
                    '₹${itemData['amount'] ?? 'N/A'}',
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildCompactDetailItem(
                    Icons.business,
                    'Department',
                    itemData['department'] ?? 'N/A',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailItem(IconData icon, String title, String value, Color color) {
    return Container(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
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
            'Available Tenders',
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
                              hintText: 'Search by tender name, location, or department...',
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
                          Icon(Icons.info_outline, size: 16, color: Colors.teal[800]),
                          SizedBox(width: 6),
                          Text(
                            'Showing available tenders for bidding',
                            style: TextStyle(
                              color: Colors.teal[800],
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
                child: _buildTenderListView(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {

            setState(() {
              _isLoading = true;
            });

            Future.delayed(Duration(milliseconds: 500), () {
              setState(() {
                _isLoading = false;
              });
            });
          },
          icon: Icon(Icons.refresh),
          label: Text('Refresh'),
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}