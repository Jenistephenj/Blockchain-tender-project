import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ContractorProfilePage extends StatefulWidget {
  const ContractorProfilePage({Key? key}) : super(key: key);

  @override
  _ContractorProfilePageState createState() => _ContractorProfilePageState();
}

class _ContractorProfilePageState extends State<ContractorProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  Map<String, dynamic> _contractorData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentUserId = '';


  int _totalTenders = 0;
  int _activeTenders = 0;
  int _completedTenders = 0;
  int _totalExpenses = 0;
  double _totalExpenseAmount = 0.0;

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
        await _loadContractorData();
        await _loadStatistics();
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

  Future<void> _loadContractorData() async {
    try {
      final snapshot = await _database
          .child('Contractor')
          .child(_currentUserId)
          .once();

      if (snapshot.snapshot.value != null) {
        setState(() {
          _contractorData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Contractor data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {

      final tendersSnapshot = await _database
          .child('tender')
          .orderByChild('userId')
          .equalTo(_currentUserId)
          .once();

      if (tendersSnapshot.snapshot.value != null) {
        Map<dynamic, dynamic> tenders = tendersSnapshot.snapshot.value as Map<dynamic, dynamic>;
        _totalTenders = tenders.length;


        int active = 0;
        int completed = 0;
        tenders.forEach((key, value) {
          Map<String, dynamic> tender = Map<String, dynamic>.from(value);
          if (tender['status'] == 'completed') {
            completed++;
          } else {
            active++;
          }
        });

        setState(() {
          _activeTenders = active;
          _completedTenders = completed;
        });
      }


      final expensesSnapshot = await _database
          .child('expense')
          .orderByChild('uid')
          .equalTo(_currentUserId)
          .once();

      if (expensesSnapshot.snapshot.value != null) {
        Map<dynamic, dynamic> expenses = expensesSnapshot.snapshot.value as Map<dynamic, dynamic>;
        _totalExpenses = expenses.length;


        double total = 0;
        expenses.forEach((key, value) {
          Map<String, dynamic> expense = Map<String, dynamic>.from(value);
          double amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0;
          total += amount;
        });

        setState(() {
          _totalExpenseAmount = total;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    await _loadContractorData();
    await _loadStatistics();
  }

  void _launchPhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showSnackBar('Cannot make phone call');
    }
  }

  void _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showSnackBar('Cannot open email client');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.teal,
      ),
    );
  }

  String _formatRegistrationDate(String dateString) {
    try {
      if (dateString.contains('T')) {

        DateTime date = DateTime.parse(dateString);
        return DateFormat('dd MMM yyyy, hh:mm a').format(date);
      } else {

        return DateFormat('dd MMM yyyy').format(DateTime.parse(dateString));
      }
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
            'Loading Profile...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refreshData,
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

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.teal.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [

          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.teal,
            ),
          ),
          SizedBox(height: 16),


          Text(
            _contractorData['name'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),



          Text(
            'Contractor ID: ${_contractorData['ckey']?.toString().substring(0, 8)}...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                icon: Icons.assignment,
                title: 'Total Tenders',
                value: _totalTenders.toString(),
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.assignment_turned_in,
                title: 'Active Tenders',
                value: _activeTenders.toString(),
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.check_circle,
                title: 'Completed',
                value: _completedTenders.toString(),
                color: Colors.teal,
              ),
              _buildStatCard(
                icon: Icons.currency_rupee,
                title: 'Total Expenses',
                value: '₹${_totalExpenseAmount.toStringAsFixed(2)}',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 30,
            color: color,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          SizedBox(height: 16),

          _buildContactItem(
            icon: Icons.email,
            title: 'Email',
            value: _contractorData['email'] ?? 'N/A',
            onTap: () {
              if (_contractorData['email'] != null) {
                _launchEmail(_contractorData['email']);
              }
            },
          ),

          _buildContactItem(
            icon: Icons.phone,
            title: 'Mobile',
            value: _contractorData['mobile'] ?? 'N/A',
            onTap: () {
              if (_contractorData['mobile'] != null) {
                _launchPhoneCall(_contractorData['mobile']);
              }
            },
          ),

          _buildContactItem(
            icon: Icons.location_on,
            title: 'Location',
            value: _contractorData['location'] ?? 'N/A',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.teal,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.teal,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          SizedBox(height: 16),

          _buildInfoItem(
            icon: Icons.location_city,
            title: 'District',
            value: _contractorData['district'] ?? 'N/A',
          ),

          _buildInfoItem(
            icon: Icons.home_work,
            title: 'Ward Number',
            value: _contractorData['wardno'] ?? 'N/A',
          ),

          _buildInfoItem(
            icon: Icons.calendar_today,
            title: 'Registration Date',
            value: _formatRegistrationDate(_contractorData['registrationDate'] ?? ''),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
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
        if (showDivider)
          Divider(height: 1, color: Colors.grey.shade200),
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
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.teal,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              SizedBox(height: 16),
              _buildStatisticsSection(),
              SizedBox(height: 16),
              _buildContactSection(),
              SizedBox(height: 16),
              _buildAdditionalInfo(),
              SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
}