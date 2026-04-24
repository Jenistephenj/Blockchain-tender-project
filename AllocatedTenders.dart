import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:tender/government/GovernmentViewExpenses.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'GovernmentHome.dart';

class AllotTenders extends StatefulWidget {
  @override
  _VieweefeTendersState createState() => _VieweefeTendersState();
}

class _VieweefeTendersState extends State<AllotTenders> {
  late StreamController<DatabaseEvent> _tenderStreamController;
  final DatabaseReference _tendersRef = FirebaseDatabase.instance.ref('tenders');
  final DatabaseReference _biddingRef = FirebaseDatabase.instance.ref('bidding');
  final DatabaseReference _contractorRef = FirebaseDatabase.instance.ref('Contractor');
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _contractorCache = {};

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

  Future<Map<String, dynamic>?> _getAllocatedContractor(String tenderId) async {
    try {
      final biddingSnapshot = await _biddingRef
          .orderByChild('tenderId')
          .equalTo(tenderId)
          .once();

      if (biddingSnapshot.snapshot.value != null) {
        final biddingData = Map<String, dynamic>.from(
            biddingSnapshot.snapshot.value as Map);


        for (var entry in biddingData.entries) {
          final bidData = Map<String, dynamic>.from(entry.value as Map);
          if (bidData['tenderstatus'] == 'Allot') {
            final contractorKey = bidData['cKey'];
            if (contractorKey != null) {

              if (_contractorCache.containsKey(contractorKey)) {
                return _contractorCache[contractorKey];
              }

              final contractorSnapshot = await _contractorRef
                  .child(contractorKey)
                  .once();

              if (contractorSnapshot.snapshot.exists) {
                final contractorData = Map<String, dynamic>.from(
                    contractorSnapshot.snapshot.value as Map);
                _contractorCache[contractorKey] = contractorData;
                return contractorData;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching contractor: $e');
    }
    return null;
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
                  'Loading Allocated Tenders...',
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
          final rawData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final filteredKeys = rawData.keys.where((key) {
            final item = Map<String, dynamic>.from(rawData[key]);
            final tenderName = (item['tenderName'] ?? '').toString().toLowerCase();
            final location = (item['location'] ?? '').toString().toLowerCase();
            final department = (item['department'] ?? '').toString().toLowerCase();
            final status = item['status'] ?? '';

            final query = searchQuery.toLowerCase();
            return (tenderName.contains(query) ||
                location.contains(query) ||
                department.contains(query)) &&
                status == 'Allot';
          }).toList();

          if (filteredKeys.isEmpty) {
            return FadeIn(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_turned_in,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 20),
                    Text(
                      searchQuery.isEmpty
                          ? 'No Allocated Tenders'
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
                          ? 'Allocate tenders to see them here'
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
            itemCount: filteredKeys.length,
            itemBuilder: (context, index) {
              final itemId = filteredKeys[index];
              final itemData = Map<String, dynamic>.from(rawData[itemId] as Map);
              final isEven = index % 2 == 0;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getAllocatedContractor(itemId),
                builder: (context, contractorSnapshot) {
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
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.assignment_turned_in,
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
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          size: 14, color: Colors.green),
                                      SizedBox(width: 6),
                                      Text(
                                        'ALLOCATED',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
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
                                  _buildDetailRow(
                                    Icons.email,
                                    'Contact Email',
                                    itemData['contactmail'] ?? 'N/A',
                                    Colors.blue,
                                  ),
                                  Divider(height: 20, color: Colors.grey[200]),
                                  _buildDetailRow(
                                    Icons.location_on,
                                    'Location',
                                    itemData['location'] ?? 'N/A',
                                    Colors.green,
                                  ),
                                  Divider(height: 20, color: Colors.grey[200]),
                                  _buildDetailRow(
                                    Icons.currency_rupee,
                                    'Amount',
                                    '₹${itemData['amount'] ?? 'N/A'}',
                                    Colors.orange,
                                  ),
                                  Divider(height: 20, color: Colors.grey[200]),
                                  _buildDetailRow(
                                    Icons.description,
                                    'Description',
                                    itemData['description'] ?? 'No description',
                                    Colors.purple,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),


                            if (contractorSnapshot.connectionState ==
                                ConnectionState.waiting)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    CircularProgressIndicator(
                                        color: Colors.teal, strokeWidth: 2),
                                    SizedBox(width: 16),
                                    Text('Loading contractor details...'),
                                  ],
                                ),
                              )
                            else if (contractorSnapshot.hasData &&
                                contractorSnapshot.data != null)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[100]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            color: Colors.blue[700], size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Allocated Contractor',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[800],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Name:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                contractorSnapshot.data!['name'] ??
                                                    'Unknown',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Email:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                contractorSnapshot.data!['email'] ??
                                                    'N/A',
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
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Mobile:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                contractorSnapshot.data!['mobile'] ??
                                                    'N/A',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Location:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                contractorSnapshot.data![
                                                'location'] ??
                                                    'N/A',
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
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.orange, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Contractor details not available',
                                        style: TextStyle(
                                          color: Colors.orange[800],
                                        ),
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
                                    onPressed: () =>
                                        _downloadDocument(itemData['documentPath']),
                                    icon: Icon(Icons.download, size: 20),
                                    label: Text('Download Document'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal[700],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding:
                                      EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.teal[300]!, width: 2),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GovernmentViewExpenses(
                                            tenderId: itemId,
                                            tenderName: itemData['tenderName'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.wallet,
                                        color: Colors.teal[700]),
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
            },
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 20),
                Text(
                  'No Allocated Tenders',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Allocate tenders to see them here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, Color color) {
    return Row(
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
              ),
              SizedBox(height: 4),
              Text(
                value,
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
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green[800]),
                          SizedBox(width: 6),
                          Text(
                            'Showing allocated tenders with contractor details',
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