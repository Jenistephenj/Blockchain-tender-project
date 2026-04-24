import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

class ViewExpenseDetails extends StatefulWidget {
  final String tenderId;
  final String tenderName;

  const ViewExpenseDetails({
    Key? key,
    required this.tenderId,
    required this.tenderName,
  }) : super(key: key);

  @override
  _ViewExpenseDetailsState createState() => _ViewExpenseDetailsState();
}

class _ViewExpenseDetailsState extends State<ViewExpenseDetails> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  late String _currentUserId;

  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  PdfController? _pdfController;
  bool _isViewingFile = false;
  String? _currentFilePath;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchExpenses();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    if (_currentFilePath != null) {
      _cleanupFile(_currentFilePath!);
    }
    super.dispose();
  }

  Future<void> _cleanupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error cleaning up file: $e');
    }
  }

  Future<void> _getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
    }
  }

  Future<void> _fetchExpenses() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final snapshot = await _database
          .child('expense')
          .orderByChild('tenderId')
          .equalTo(widget.tenderId)
          .once();

      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempExpenses = [];

        data.forEach((key, value) {
          Map<String, dynamic> expense = Map<String, dynamic>.from(value);
          expense['key'] = key;


          if (expense['uid'] == _currentUserId) {
            tempExpenses.add(expense);
          }
        });


        tempExpenses.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        setState(() {
          _expenses = tempExpenses;
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

  Future<void> _refreshData() async {
    await _fetchExpenses();
  }

  String _formatDate(int timestamp) {
    try {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
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

  Widget _getFileIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx')) {
      return Icon(Icons.description, color: Colors.blue);
    } else if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.gif')) {
      return Icon(Icons.image, color: Colors.green);
    } else {
      return Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _getFileType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) return 'PDF Document';
    if (fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx')) return 'Word Document';
    if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg')) return 'JPEG Image';
    if (fileName.toLowerCase().endsWith('.png')) return 'PNG Image';
    if (fileName.toLowerCase().endsWith('.gif')) return 'GIF Image';
    return 'Document';
  }

  Future<String> _downloadFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      throw Exception('Download error: $e');
    }
  }

  Future<void> _viewFile(String fileUrl, String fileName) async {
    try {
      setState(() {
        _isViewingFile = true;
      });


      final filePath = await _downloadFile(fileUrl, fileName);


      if (_currentFilePath != null && _currentFilePath != filePath) {
        await _cleanupFile(_currentFilePath!);
      }
      _currentFilePath = filePath;


      if (fileName.toLowerCase().endsWith('.pdf')) {
        _openPdf(filePath);
      } else if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.gif')) {
        _openImage(filePath, fileUrl);
      } else {

        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          throw Exception('Cannot open file: ${result.message}');
        }
        setState(() {
          _isViewingFile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isViewingFile = false;
      });
      _showErrorDialog('Cannot open file: $e');
    }
  }

  void _openPdf(String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('PDF Viewer'),
            backgroundColor: Colors.teal,
          ),
          body: PdfView(
            controller: PdfController(
              document: PdfDocument.openFile(filePath),
            ),
          ),
        ),
      ),
    ).then((_) {
      setState(() {
        _isViewingFile = false;
      });
    });
  }

  void _openImage(String filePath, String originalUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Image Viewer'),
            backgroundColor: Colors.teal,
            actions: [
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () {

                },
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            child: PhotoView(
              imageProvider: FileImage(File(filePath)),
              backgroundDecoration: BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
            ),
          ),
        ),
      ),
    ).then((_) {
      setState(() {
        _isViewingFile = false;
      });
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusText = 'Approved ✓';
        break;
      case 'rejected':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        statusText = 'Rejected ✗';
        break;
      case 'pending':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        statusText = 'Pending ⏳';
        break;
      default:
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        statusText = 'Requested';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
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
            'You haven\'t submitted any expenses for this tender yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.tenderName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isViewingFile
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.teal,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Loading file...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.teal,
        backgroundColor: Colors.white,
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
            ? _buildErrorState()
            : _expenses.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _expenses.length,
          itemBuilder: (context, index) {
            final expense = _expenses[index];
            return _buildExpenseCard(expense);
          },
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final hasFileProof = expense['file_proof_url'] != null &&
        (expense['file_proof_url'] as String).isNotEmpty;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                _buildStatusChip(expense['status1'] ?? 'request'),
              ],
            ),

            SizedBox(height: 12),


            Text(
              expense['description'] ?? 'No description',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),

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
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: _formatDate(expense['timestamp'] ?? 0),
                ),
                _buildDetailItem(
                  icon: Icons.fingerprint,
                  label: 'Blockchain',
                  value: '✓ Verified',
                  valueColor: Colors.green,
                ),
              ],
            ),

            SizedBox(height: 16),


            if (hasFileProof)
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
                    onTap: () {
                      _viewFile(
                        expense['file_proof_url'],
                        expense['file_name'] ?? 'proof_file',
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
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
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _getFileIcon(expense['file_name'] ?? ''),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense['file_name'] ?? 'Proof File',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _getFileType(expense['file_name'] ?? ''),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (expense['file_size'] != null)
                                  Text(
                                    expense['file_size'],
                                    style: TextStyle(
                                      fontSize: 12,
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

                  SizedBox(height: 8),
                  Text(
                    'Tap to view in app',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),


            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.block,
                        size: 16,
                        color: Colors.teal,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Blockchain Verification',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  if (expense['blockchain_tx_hash'] != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tx Hash: ${expense['blockchain_tx_hash'].toString().substring(0, 16)}...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontFamily: 'Monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.teal,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
}