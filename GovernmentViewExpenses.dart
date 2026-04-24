import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class GovernmentViewExpenses extends StatefulWidget {
  final String tenderId;
  final String tenderName;

  const GovernmentViewExpenses({
    Key? key,
    required this.tenderId,
    required this.tenderName,
  }) : super(key: key);

  @override
  _GovernmentViewExpensesState createState() => _GovernmentViewExpensesState();
}

class _GovernmentViewExpensesState extends State<GovernmentViewExpenses> {
  final DatabaseReference _expensesRef = FirebaseDatabase.instance.ref('expense');
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedFilter = 'all';
  String _selectedStatusFilter = 'all';


  double _totalAmount = 0;
  int _totalExpenses = 0;
  Map<String, double> _dailyTotals = {};
  Map<String, int> _dailyCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final snapshot = await _expensesRef
          .orderByChild('tenderId')
          .equalTo(widget.tenderId)
          .once();

      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempExpenses = [];

        data.forEach((key, value) {
          Map<String, dynamic> expense = Map<String, dynamic>.from(value);
          expense['key'] = key;
          tempExpenses.add(expense);
        });


        tempExpenses.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));


        _calculateStatistics(tempExpenses);

        setState(() {
          _expenses = tempExpenses;
          _filteredExpenses = tempExpenses;
          _applyFilters();
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading expenses: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics(List<Map<String, dynamic>> expenses) {
    double total = 0;
    int count = 0;
    Map<String, double> dailyTotals = {};
    Map<String, int> dailyCounts = {};

    for (var expense in expenses) {
      double amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0;
      total += amount;
      count++;

      String date = expense['date'] ?? 'Unknown';
      dailyTotals[date] = (dailyTotals[date] ?? 0) + amount;
      dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
    }

    setState(() {
      _totalAmount = total;
      _totalExpenses = count;
      _dailyTotals = dailyTotals;
      _dailyCounts = dailyCounts;
    });
  }

  void _applyFilters() {
    setState(() {

      List<Map<String, dynamic>> dateFiltered = [];

      if (_selectedFilter == 'all') {
        dateFiltered = List.from(_expenses);
      } else {
        DateTime now = DateTime.now();
        dateFiltered = _expenses.where((expense) {
          try {
            String dateString = expense['date'] ?? '';
            if (dateString.isEmpty) return false;

            DateTime expenseDate = DateFormat('yyyy-MM-dd').parse(dateString);

            switch (_selectedFilter) {
              case 'today':
                return _isSameDay(expenseDate, now);
              case 'week':
                DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
                return expenseDate.isAfter(weekStart.subtract(Duration(days: 1)));
              case 'month':
                return expenseDate.month == now.month && expenseDate.year == now.year;
              default:
                return true;
            }
          } catch (e) {
            return false;
          }
        }).toList();
      }


      if (_selectedStatusFilter == 'all') {
        _filteredExpenses = dateFiltered;
      } else {
        _filteredExpenses = dateFiltered.where((expense) {
          String status2 = expense['status2'] ?? 'request';
          switch (_selectedStatusFilter) {
            case 'pending':
              return status2 == 'request';
            case 'approved':
              return status2 == 'approved';
            case 'rejected':
              return status2 == 'rejected';
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _viewImage(String imageUrl) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Expense Proof'),
            backgroundColor: Colors.teal,
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateGovernmentStatus(String expenseKey, String status) async {
    try {

      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm $status'),
          content: Text('Are you sure you want to $status this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                status == 'approved' ? 'Approve' : 'Reject',
                style: TextStyle(
                  color: status == 'approved' ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;


      await _expensesRef.child(expenseKey).update({
        'status2': status,
      });


      await _fetchExpenses();


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense ${status == 'approved' ? 'approved' : 'rejected'} successfully'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatAmount(String amount) {
    try {
      double value = double.tryParse(amount) ?? 0;
      return '₹${value.toStringAsFixed(2)}';
    } catch (e) {
      return '₹0.00';
    }
  }

  String _formatTimestamp(int timestamp) {
    try {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildStatusChip(String status, String type) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = '${type == 'dept' ? 'Dept ' : 'Gov '}Approved';
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = '${type == 'dept' ? 'Dept ' : 'Gov '}Rejected';
        break;
      case 'request':
      default:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = '${type == 'dept' ? 'Dept ' : 'Gov '}Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
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
            'Loading Expenses...',
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
            onPressed: _fetchExpenses,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.money_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 20),
          Text(
            'No Expenses Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'No expenses have been submitted for this tender yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
            label: Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.teal.shade800],
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
                  Icons.currency_rupee,
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
                      widget.tenderName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Government Expense Approval',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                value: _formatAmount(_totalAmount.toString()),
                label: 'Total Amount',
                icon: Icons.currency_rupee,
              ),
              _buildStatCard(
                value: _totalExpenses.toString(),
                label: 'Total Expenses',
                icon: Icons.receipt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String value, required String label, required IconData icon}) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChips() {
    List<Map<String, dynamic>> filters = [
      {'label': 'All Dates', 'value': 'all'},
      {'label': 'Today', 'value': 'today'},
      {'label': 'This Week', 'value': 'week'},
      {'label': 'This Month', 'value': 'month'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filter['label']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['value'];
                  _applyFilters();
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    List<Map<String, dynamic>> filters = [
      {'label': 'All Status', 'value': 'all'},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Approved', 'value': 'approved'},
      {'label': 'Rejected', 'value': 'rejected'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _selectedStatusFilter == filter['value'];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filter['label']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatusFilter = filter['value'];
                  _applyFilters();
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: filter['value'] == 'pending' ? Colors.orange :
              filter['value'] == 'approved' ? Colors.green :
              filter['value'] == 'rejected' ? Colors.red : Colors.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApprovalActions(Map<String, dynamic> expense) {
    String govStatus = expense['status2'] ?? 'request';

    if (govStatus == 'request') {
      return Column(
        children: [
          SizedBox(height: 12),
          Text(
            'Government Approval Action',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.teal[800],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateGovernmentStatus(expense['key'], 'approved'),
                  icon: Icon(Icons.check_circle, size: 18),
                  label: Text('Approve Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateGovernmentStatus(expense['key'], 'rejected'),
                  icon: Icon(Icons.cancel, size: 18),
                  label: Text('Reject Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    bool hasProof = expense['file_proof_url'] != null &&
        (expense['file_proof_url'] as String).isNotEmpty;

    String deptStatus = expense['status1'] ?? 'request';
    String govStatus = expense['status2'] ?? 'request';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.teal.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatAmount(expense['amount'] ?? '0'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.teal),
                        SizedBox(width: 6),
                        Text(
                          expense['date'] ?? 'Unknown Date',
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

              SizedBox(height: 12),


              Text(
                expense['description'] ?? 'No description',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),

              SizedBox(height: 16),


              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Column(
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Department Approval:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        _buildStatusChip(deptStatus, 'dept'),
                      ],
                    ),
                    SizedBox(height: 12),


                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Government Approval:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal[800],
                          ),
                        ),
                        _buildStatusChip(govStatus, 'gov'),
                      ],
                    ),
                  ],
                ),
              ),


              _buildApprovalActions(expense),

              SizedBox(height: 16),


              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 8,
                children: [
                  _buildDetailItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: expense['location'] ?? 'N/A',
                  ),
                  _buildDetailItem(
                    icon: Icons.phone,
                    label: 'Mobile',
                    value: expense['mobile'] ?? 'N/A',
                  ),
                  _buildDetailItem(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: _formatTimestamp(expense['timestamp'] ?? 0),
                  ),
                  _buildDetailItem(
                    icon: Icons.block,
                    label: 'Blockchain',
                    value: '✓ Verified',
                    valueColor: Colors.green,
                  ),
                ],
              ),

              SizedBox(height: 16),


              if (hasProof)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(),
                    SizedBox(height: 12),
                    Text(
                      'Proof Document',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _viewImage(expense['file_proof_url']),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.shade100,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense['file_name'] ?? 'Proof Image',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal[800],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Click to view image',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal[600],
                                    ),
                                  ),
                                  if (expense['file_size'] != null)
                                    Text(
                                      expense['file_size'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 8),


              if (expense['blockchain_tx_hash'] != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: 'Blockchain Verified',
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.security,
                          size: 18,
                          color: Colors.teal,
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
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.teal,
          elevation: 0,
          title: Text(
            'Government Expense Approval',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchExpenses,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : _hasError
            ? _buildErrorState()
            : _expenses.isEmpty
            ? _buildEmptyState()
            : Column(
          children: [
            _buildHeader(),
            SizedBox(height: 16),


            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Date:',
                    style: TextStyle(
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDateFilterChips(),
                ],
              ),
            ),


            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Status:',
                    style: TextStyle(
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildStatusFilterChips(),
                ],
              ),
            ),

            SizedBox(height: 8),


            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredExpenses.length} expense${_filteredExpenses.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedFilter != 'all' || _selectedStatusFilter != 'all')
                    Text(
                      'Filters: ${_selectedFilter != 'all' ? 'Date: $_selectedFilter' : ''}${_selectedStatusFilter != 'all' ? ' Status: $_selectedStatusFilter' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 8),


            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchExpenses,
                color: Colors.teal,
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: 20),
                  itemCount: _filteredExpenses.length,
                  itemBuilder: (context, index) {
                    return _buildExpenseCard(_filteredExpenses[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}