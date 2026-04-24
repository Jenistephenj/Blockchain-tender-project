import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tender/user/UserHome.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');

  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentUserId = '';


  int _totalComplaints = 0;
  int _activeComplaints = 0;
  int _resolvedComplaints = 0;

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
        await _loadUserData();
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

  Future<void> _loadUserData() async {
    try {
      final snapshot = await _usersRef
          .child(_currentUserId)
          .once();

      if (snapshot.snapshot.value != null) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'User data not found';
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

      final complaintsSnapshot = await FirebaseDatabase.instance
          .ref('complaints')
          .orderByChild('ukey')
          .equalTo(_currentUserId)
          .once();

      if (complaintsSnapshot.snapshot.value != null) {
        Map<dynamic, dynamic> complaints =
        complaintsSnapshot.snapshot.value as Map<dynamic, dynamic>;
        _totalComplaints = complaints.length;


        int active = 0;
        int resolved = 0;
        complaints.forEach((key, value) {
          Map<String, dynamic> complaint = Map<String, dynamic>.from(value);
          if (complaint['status'] == 'approved' || complaint['status'] == 'rejected') {
            resolved++;
          } else {
            active++;
          }
        });

        setState(() {
          _activeComplaints = active;
          _resolvedComplaints = resolved;
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
    await _loadUserData();
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String statusText;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'active':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusText = 'Active ✓';
        icon = Icons.verified_user;
        break;
      case 'inactive':
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusText = 'Inactive';
        icon = Icons.pause_circle;
        break;
      case 'suspended':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        statusText = 'Suspended ✗';
        icon = Icons.block;
        break;
      default:
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        statusText = 'Unknown';
        icon = Icons.help_outline;
    }

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      avatar: icon != null ? Icon(icon, size: 16, color: textColor) : null,
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
            'Loading Profile...',
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
      padding: EdgeInsets.all(25),
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
            _userData['name'] ?? 'Citizen User',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),

          _buildStatusChip(_userData['status'] ?? 'active'),
          SizedBox(height: 8),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Public Citizen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStats() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.teal, size: 24),
              SizedBox(width: 12),
              Text(
                'Your Civic Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildStatCard(
                value: _totalComplaints.toString(),
                label: 'Total Complaints',
                icon: Icons.report_problem,
                color: Colors.blue,
              ),
              _buildStatCard(
                value: _activeComplaints.toString(),
                label: 'Active',
                icon: Icons.access_time,
                color: Colors.orange,
              ),
              _buildStatCard(
                value: _resolvedComplaints.toString(),
                label: 'Resolved',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ),

          SizedBox(height: 20),

          if (_totalComplaints == 0)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You haven\'t submitted any complaints yet. Start participating in governance!',
                      style: TextStyle(
                        color: Colors.teal[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
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
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.teal, size: 24),
              SizedBox(width: 12),
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          _buildInfoItem(
            icon: Icons.email,
            title: 'Email Address',
            value: _userData['email'] ?? 'N/A',
            isClickable: true,
            onTap: () {
              if (_userData['email'] != null) {
                _launchEmail(_userData['email']);
              }
            },
          ),

          _buildInfoItem(
            icon: Icons.phone,
            title: 'Mobile Number',
            value: _userData['mobile'] ?? 'N/A',
            isClickable: true,
            onTap: () {
              if (_userData['mobile'] != null) {
                _launchPhoneCall(_userData['mobile']);
              }
            },
          ),

          _buildInfoItem(
            icon: Icons.location_on,
            title: 'Location',
            value: _userData['location'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenDetails() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: Colors.teal, size: 24),
              SizedBox(width: 12),
              Text(
                'Citizen Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          _buildInfoItem(
            icon: Icons.location_city,
            title: 'District',
            value: _userData['district'] ?? 'N/A',
          ),

          _buildInfoItem(
            icon: Icons.home_work,
            title: 'Ward Number',
            value: _userData['wardno'] ?? 'N/A',
          ),

          _buildInfoItem(
            icon: Icons.calendar_today,
            title: 'Registration Date',
            value: _formatRegistrationDate(_userData['registrationDate'] ?? ''),
          ),

          _buildInfoItem(
            icon: Icons.fingerprint,
            title: 'User ID',
            value: _userData['ukey']?.toString().substring(0, 12) ?? 'N/A',
            showDivider: false,
            isCopyable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    bool isClickable = false,
    bool isCopyable = false,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: isClickable ? onTap : null,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isClickable)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.teal,
                  ),
                if (isCopyable)
                  IconButton(
                    icon: Icon(Icons.copy, size: 18),
                    color: Colors.teal,
                    onPressed: () {
                      // TODO: Implement copy to clipboard
                      _showSnackBar('Copied to clipboard');
                    },
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

  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [

          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => UserHome()),
                      (route) => false,
                );
                // TODO: Navigate to complaints page
              },
              icon: Icon(Icons.home, size: 20),
              label: Text('Back To Home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: BorderSide(color: Colors.teal),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeBadge() {
    String userType = _userData['userType'] ?? 'citizen';
    Color badgeColor;
    String badgeText;

    switch (userType.toLowerCase()) {
      case 'citizen':
        badgeColor = Colors.blue.shade100;
        badgeText = 'Verified Citizen';
        break;
      case 'admin':
        badgeColor = Colors.red.shade100;
        badgeText = 'Administrator';
        break;
      default:
        badgeColor = Colors.grey.shade100;
        badgeText = 'User';
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: Colors.teal),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                Text(
                  'Public Portal Access Granted',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal[600],
                  ),
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
              _buildUserTypeBadge(),
              SizedBox(height: 20),
              _buildActivityStats(),
              SizedBox(height: 16),
              _buildPersonalInfo(),
              SizedBox(height: 16),
              _buildCitizenDetails(),
              SizedBox(height: 20),
              _buildActionButtons(),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}