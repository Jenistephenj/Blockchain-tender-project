import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:tender/contractor/ContracterHome.dart';
import 'AddExpenses.dart';
import 'ContractorViewTheirExpenses.dart';

class CpntractorMyTenders extends StatefulWidget {
  @override
  _viebidState createState() => _viebidState();
}

class _viebidState extends State<CpntractorMyTenders> {
  late StreamController<DatabaseEvent> _tenderStreamController;
  final DatabaseReference _biddingRef = FirebaseDatabase.instance.ref('bidding');
  final DatabaseReference _contractorRef = FirebaseDatabase.instance.ref('Contractor');
  final DatabaseReference _tendersRef = FirebaseDatabase.instance.ref('tenders');

  Map<String, dynamic> _contractorData = {};
  late String _currentUserId;
  bool _isLoading = true;
  bool _isContractorLoading = true;
  Map<String, dynamic> _tenderDetailsCache = {};
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "allot";

  @override
  void initState() {
    super.initState();

    final User? user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? '';
    _tenderStreamController = StreamController<DatabaseEvent>();


    _biddingRef
        .orderByChild('cKey')
        .equalTo(_currentUserId)
        .onValue
        .listen((event) {
      _tenderStreamController.add(event);
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    _fetchContractorDetails();
  }

  Future<void> _fetchContractorDetails() async {
    try {
      DatabaseEvent event = await _contractorRef.child(_currentUserId).once();
      if (event.snapshot.value != null) {
        setState(() {
          _contractorData = Map<String, dynamic>.from(event.snapshot.value as Map);
          _isContractorLoading = false;
        });
      } else {
        setState(() {
          _isContractorLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isContractorLoading = false;
      });
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'allot':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'request':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'allot':
        return 'Allocated';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'request':
        return 'Submitted';
      default:
        return 'Unknown';
    }
  }


  List<MapEntry<String, dynamic>> _filterTenders(Map<String, dynamic> rawData) {
    return rawData.entries.where((entry) {
      final itemData = Map<String, dynamic>.from(entry.value as Map);
      final tenderName = (itemData['tenderName'] ?? '').toString().toLowerCase();
      final department = (itemData['department'] ?? '').toString().toLowerCase();
      final status = (itemData['tenderstatus'] ?? '').toString().toLowerCase();


      final matchesStatus = _selectedFilter == 'all' ||
          status == _selectedFilter.toLowerCase();


      final query = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          tenderName.contains(query) ||
          department.contains(query) ||
          status.contains(query);


      return itemData['cKey'] == _currentUserId &&
          matchesStatus &&
          matchesSearch;
    }).toList();
  }



  @override
  void dispose() {
    _tenderStreamController.close();
    _searchController.dispose();
    super.dispose();
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
                  'Loading Your Tenders...',
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
          final filteredTenders = _filterTenders(rawData);

          if (filteredTenders.isEmpty) {
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
                      _searchQuery.isEmpty
                          ? 'No Allocated Tenders'
                          : 'No results for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _searchQuery.isEmpty && _selectedFilter == 'allot'
                          ? 'You don\'t have any allocated tenders yet'
                          : _selectedFilter != 'allot'
                          ? 'No ${_selectedFilter} tenders found'
                          : 'Try different search terms',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
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


          filteredTenders.sort((a, b) {
            final statusA = (a.value as Map)['tenderstatus'] ?? '';
            final statusB = (b.value as Map)['tenderstatus'] ?? '';
            final timeA = (a.value as Map)['timestamp'] ?? '';
            final timeB = (b.value as Map)['timestamp'] ?? '';

            if (statusA != statusB) {
              if (statusA.toLowerCase() == 'allot') return -1;
              if (statusB.toLowerCase() == 'allot') return 1;
              return statusB.compareTo(statusA);
            }
            return (timeB as String).compareTo(timeA as String);
          });

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: filteredTenders.length,
            itemBuilder: (context, index) {
              final entry = filteredTenders[index];
              final itemId = entry.key;
              final itemData = Map<String, dynamic>.from(entry.value as Map);
              final status = itemData['tenderstatus']?.toString() ?? 'request';
              final statusColor = _getStatusColor(status);
              final isEven = index % 2 == 0;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getTenderDetails(itemData['tenderId'] ?? ''),
                builder: (context, tenderSnapshot) {
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
                            // Header Row with Status
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor,
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
                                        itemData['tenderName'] ?? 'Unknown Tender',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  _buildDetailItem(
                                    Icons.currency_rupee,
                                    'Your Bid Amount',
                                    '₹${itemData['bidAmount'] ?? 'N/A'}',
                                    Colors.green,
                                  ),
                                  SizedBox(height: 12),

                                  if (tenderSnapshot.hasData && tenderSnapshot.data != null)
                                    _buildDetailItem(
                                      Icons.monetization_on,
                                      'Tender Amount',
                                      '₹${tenderSnapshot.data!['amount'] ?? 'N/A'}',
                                      Colors.orange,
                                    ),
                                  SizedBox(height: 12),

                                  if (tenderSnapshot.hasData && tenderSnapshot.data != null)
                                    _buildDetailItem(
                                      Icons.location_on,
                                      'Location',
                                      tenderSnapshot.data!['location'] ?? 'N/A',
                                      Colors.blue,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person,
                                          color: Colors.teal[700], size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Your Information',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.teal[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  if (_isContractorLoading)
                                    Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.teal,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSimpleDetailItem(
                                                'Name',
                                                _contractorData['name'] ?? 'N/A',
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: _buildSimpleDetailItem(
                                                'Email',
                                                _contractorData['email'] ?? 'N/A',
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSimpleDetailItem(
                                                'Mobile',
                                                _contractorData['mobile'] ?? 'N/A',
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: _buildSimpleDetailItem(
                                                'Location',
                                                _contractorData['location'] ?? 'N/A',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),


                            if (status.toLowerCase() == 'allot')
                              Container(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExpenseDetailsPage(
                                          tenderId: itemData['tenderId'] ?? '',
                                          tenderName: itemData['tenderName'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.add, size: 20),
                                  label: Text(
                                    'ADD EXPENSES',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[700],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 5,
                                    shadowColor: Colors.teal.withOpacity(0.3),
                                  ),
                                ),
                              ),

                            SizedBox(height: 20),


                            if (status.toLowerCase() == 'allot')
                              Container(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ViewExpenseDetails(
                                          tenderId: itemData['tenderId'] ?? '',
                                          tenderName: itemData['tenderName'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.currency_rupee, size: 20),
                                  label: Text(
                                    'VIEW EXPENSES',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[700],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 5,
                                    shadowColor: Colors.teal.withOpacity(0.3),
                                  ),
                                ),
                              ),


                            if (status.toLowerCase() != 'allot')
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text(
                                      'Expense tracking available after allocation',
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w500,
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
                  Icons.assignment_turned_in,
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
                  'You don\'t have any allocated tenders yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  Widget _buildSimpleDetailItem(String title, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          MaterialPageRoute(builder: (context) => ContracterHome()),
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
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
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
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedFilter == 'allot'
                        ? Colors.green.shade50
                        : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedFilter == 'allot'
                          ? Colors.green.shade200
                          : Colors.teal.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        color: _selectedFilter == 'allot'
                            ? Colors.green
                            : Colors.teal,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFilter == 'allot'
                              ? 'Showing allocated tenders only - Expense tracking enabled'
                              : 'Showing ${_selectedFilter} tenders',
                          style: TextStyle(
                            color: _selectedFilter == 'allot'
                                ? Colors.green.shade800
                                : Colors.teal.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ContracterHome(),
              ),
            );
          },
          icon: Icon(Icons.arrow_back),
          label: Text('Back to Home'),
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}