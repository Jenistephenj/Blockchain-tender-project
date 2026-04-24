import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'DepartmentHome.dart';

class DepartmentViewBidding extends StatefulWidget {
  final String? tenderId;
  final String? tenderName;

  const DepartmentViewBidding({
    Key? key,
    this.tenderId,
    this.tenderName,
  }) : super(key: key);

  @override
  _viebidState createState() => _viebidState();
}

class _viebidState extends State<DepartmentViewBidding> {
  late StreamController<DatabaseEvent> _tenderStreamController;
  final DatabaseReference _biddingRef = FirebaseDatabase.instance.ref('bidding');
  final DatabaseReference _tenderRef = FirebaseDatabase.instance.ref('tenders');
  final DatabaseReference _contractorRef = FirebaseDatabase.instance.ref('Contractor');
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isLoading = true;
  Map<String, dynamic> _contractorCache = {};

  @override
  void initState() {
    super.initState();
    print("Tender ID: ${widget.tenderId}");
    _tenderStreamController = StreamController<DatabaseEvent>();
    if (widget.tenderId != null) {
      _biddingRef
          .orderByChild('tenderId')
          .equalTo(widget.tenderId)
          .onValue
          .listen((event) {
        _tenderStreamController.add(event);
        if (_isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tenderStreamController.close();
    _searchController.dispose();
    super.dispose();
  }


  Future<Map<String, dynamic>?> _getContractorData(String ckey) async {
    if (_contractorCache.containsKey(ckey)) {
      return _contractorCache[ckey];
    }

    try {
      final snapshot = await _contractorRef.child(ckey).once();
      if (snapshot.snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        _contractorCache[ckey] = data;
        return data;
      }
    } catch (e) {
      print('Error fetching contractor data: $e');
    }
    return null;
  }

  Widget _buildBiddingListView() {
    return StreamBuilder<DatabaseEvent>(
      stream: _tenderStreamController.stream,
      builder: (context, snapshot) {
        if (_isLoading) {
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
                  'Loading Bids...',
                  style: TextStyle(
                    color: Colors.blueGrey[800],
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
          final biddingItems = rawData.entries.toList();

          if (biddingItems.isEmpty) {
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
                      'No Bids Received Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Check back later for bids on this tender',
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
            itemCount: biddingItems.length,
            itemBuilder: (context, index) {
              final entry = biddingItems[index];
              final itemId = entry.key;
              final itemData = Map<String, dynamic>.from(entry.value as Map);
              final ckey = itemData['cKey'];
              final bidAmount = itemData['bidAmount'] ?? 'N/A';
              final isEven = index % 2 == 0;

              if (ckey == null) {
                return Container();
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getContractorData(ckey),
                builder: (context, contractorSnapshot) {
                  if (contractorSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard();
                  }

                  if (!contractorSnapshot.hasData || contractorSnapshot.data == null) {
                    return _buildErrorCard('Contractor data not found');
                  }

                  final contractorData = contractorSnapshot.data!;
                  final contractorName = contractorData['name'] ?? 'Unknown Contractor';
                  final contractorEmail = contractorData['email'] ?? 'N/A';
                  final contractorMobile = contractorData['mobile'] ?? 'N/A';
                  final contractorLocation = contractorData['location'] ?? 'N/A';


                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch =
                        contractorName.toLowerCase().contains(query) ||
                            contractorEmail.toLowerCase().contains(query) ||
                            contractorMobile.contains(query) ||
                            bidAmount.toString().contains(query);

                    if (!matchesSearch) {
                      return Container();
                    }
                  }

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
                                    color: Colors.blueGrey[900],
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
                                        contractorName,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey[900],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        widget.tenderName ?? 'Unknown Tender',
                                        style: TextStyle(
                                          color: Colors.blueGrey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),


                            _buildContractorDetailsSection(
                              contractorEmail,
                              contractorMobile,
                              contractorLocation,
                              bidAmount,
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
                  'No Bids Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'No contractors have bid on this tender yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContractorDetailsSection(
      String email,
      String mobile,
      String location,
      String bidAmount,
      ) {
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
                  child: _buildDetailItem(
                    Icons.email,
                    'Email',
                    email,
                    Colors.blueGrey,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDetailItem(
                    Icons.phone,
                    'Mobile',
                    mobile,
                    Colors.blueAccent,
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
                  child: _buildDetailItem(
                    Icons.location_on,
                    'Location',
                    location,
                    Colors.deepOrange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDetailItem(
                    Icons.currency_rupee,
                    'Bid Amount',
                    '₹$bidAmount',
                    Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value, Color color) {
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

  Widget _buildLoadingCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircularProgressIndicator(color: Colors.blueGrey[900]),
            SizedBox(width: 20),
            Text('Loading contractor details...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: Colors.red[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool? shouldGoBack = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Leave Bidding Page'),
            content: Text('Are you sure you want to go back? All unsaved changes will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Stay', style: TextStyle(color: Colors.blueGrey[900])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[900],
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DepartmentHome()),
                  );
                },
                child: Text('Leave', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (shouldGoBack == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DepartmentHome()),
          );
        }
        return shouldGoBack ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Bidding Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          backgroundColor: Colors.blueGrey[900],
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
                              hintText: 'Search by contractor name, email, or bid amount...',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blueGrey[900]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Showing bids for: ${widget.tenderName ?? "Tender"}',
                              style: TextStyle(
                                color: Colors.blueGrey[900],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.blue[800]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select the best contractor for allocation',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
                builder: (context) => DepartmentHome(),
              ),
            );
          },
          icon: Icon(Icons.arrow_back),
          label: Text('Back to Dashboard'),
          backgroundColor: Colors.blueGrey[900],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}