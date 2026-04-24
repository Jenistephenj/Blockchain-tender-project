import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class GovernmentDepartmentView extends StatefulWidget {
  @override
  _GovernmentDepartmentViewState createState() => _GovernmentDepartmentViewState();
}

class _GovernmentDepartmentViewState extends State<GovernmentDepartmentView> {
  final DatabaseReference _departmentRef = FirebaseDatabase.instance.ref('Department');

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _filteredDepartments = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final snapshot = await _departmentRef.once();

      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempDepartments = [];

        data.forEach((key, value) {
          Map<String, dynamic> department = Map<String, dynamic>.from(value);
          department['uid'] = key;
          tempDepartments.add(department);
        });


        tempDepartments.sort((a, b) {
          try {
            DateTime dateA = DateTime.parse(a['registrationDate'] ?? '');
            DateTime dateB = DateTime.parse(b['registrationDate'] ?? '');
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          _departments = tempDepartments;
          _filteredDepartments = tempDepartments;
          _applyFilters();
        });
      } else {
        setState(() {
          _departments = [];
          _filteredDepartments = [];
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading departments: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_departments);


    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((department) {
        final name = (department['name'] ?? '').toString().toLowerCase();
        final email = (department['email'] ?? '').toString().toLowerCase();
        final location = (department['location'] ?? '').toString().toLowerCase();
        final district = (department['district'] ?? '').toString().toLowerCase();
        final wardno = (department['wardno'] ?? '').toString().toLowerCase();

        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            location.contains(query) ||
            district.contains(query) ||
            wardno.contains(query);
      }).toList();
    }


    if (_selectedFilter == 'government') {
      filtered = filtered.where((department) =>
      (department['departmentType'] ?? '').toString().toLowerCase() == 'government'
      ).toList();
    } else if (_selectedFilter == 'private') {
      filtered = filtered.where((department) =>
      (department['departmentType'] ?? '').toString().toLowerCase() == 'private'
      ).toList();
    } else if (_selectedFilter == 'pending') {
      filtered = filtered.where((department) =>
      (department['status'] ?? '').toString().toLowerCase() == 'pending_verification'
      ).toList();
    } else if (_selectedFilter == 'active') {
      filtered = filtered.where((department) =>
      (department['status'] ?? '').toString().toLowerCase() == 'active'
      ).toList();
    }

    setState(() {
      _filteredDepartments = filtered;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
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
            'Loading Departments...',
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
            onPressed: _fetchDepartments,
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
            Icons.account_balance,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 20),
          Text(
            'No Departments Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _searchQuery.isEmpty
                ? 'No departments are registered yet'
                : 'No departments found for "$_searchQuery"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchDepartments,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department, int index) {
    final bool isEven = index % 2 == 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    department['name'] ?? 'Unknown Department',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              ],
            ),

            SizedBox(height: 8),


            Row(
              children: [

                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registered: ${_formatDate(department['registrationDate'] ?? '')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),


            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildDetailItem(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: department['location'] ?? 'N/A',
                  color: Colors.orange,
                ),
                _buildDetailItem(
                  icon: Icons.location_city,
                  label: 'District',
                  value: department['district'] ?? 'N/A',
                  color: Colors.teal,
                ),
                _buildDetailItem(
                  icon: Icons.email,
                  label: 'Email',
                  value: department['email'] ?? 'N/A',
                  color: Colors.red,
                ),
                _buildDetailItem(
                  icon: Icons.phone,
                  label: 'Mobile',
                  value: department['mobile'] ?? 'N/A',
                  color: Colors.green,
                ),
              ],
            ),

            SizedBox(height: 12),


            Container(
              padding: EdgeInsets.all(12),
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
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          department['wardno'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Department ID',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          department['uid']?.toString().substring(0, 8) ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal[700],
                            fontFamily: 'Monospace',
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

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[700]!, Colors.teal[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.account_balance,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Departments',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'View and manage registered departments',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),


        ],
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
                    hintText: 'Search by name, email, location, district...',
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
                    _applyFilters();
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
                    _applyFilters();
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
    return Scaffold(
      backgroundColor: Colors.teal[50],
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
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
            ? _buildErrorState()
            : _departments.isEmpty
            ? _buildEmptyState()
            : Column(
          children: [
            _buildHeader(),

            _buildSearchBar(),


            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredDepartments.length} department${_filteredDepartments.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedFilter != 'all' || _searchQuery.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt, size: 14, color: Colors.teal[800]),
                          SizedBox(width: 4),
                          Text(
                            'Filtered',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal[800],
                              fontWeight: FontWeight.w600,
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
              child: RefreshIndicator(
                onRefresh: _fetchDepartments,
                color: Colors.teal[700],
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: 20),
                  itemCount: _filteredDepartments.length,
                  itemBuilder: (context, index) {
                    return _buildDepartmentCard(_filteredDepartments[index], index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchDepartments,
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Departments',
      ),
    );
  }
}