import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'DepartmentHome.dart';

class DepartmentViewComplaints extends StatefulWidget {
  @override
  _DepartmentViewComplaintsState createState() => _DepartmentViewComplaintsState();
}

class _DepartmentViewComplaintsState extends State<DepartmentViewComplaints> {
  final DatabaseReference _complaintsRef = FirebaseDatabase.instance.ref('complaints');
  final DatabaseReference _departmentsRef = FirebaseDatabase.instance.ref('Department');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Map<String, dynamic>> _allComplaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  String? _departmentName;
  String? _departmentWard;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';


  Map<String, bool> _showCompletionDialog = {};
  Map<String, String> _completionNotes = {};
  Map<String, File?> _completionImages = {};
  Map<String, bool> _uploadingProof = {};

  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();

    _completionImages.values.where((file) => file != null).forEach((file) => file?.delete());
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });


      await _getDepartmentDetails();


      await _fetchComplaints();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getDepartmentDetails() async {
    try {
      User? user = _auth.currentUser;
      String? userId = user?.uid;

      if (userId != null) {
        final deptSnapshot = await _departmentsRef.child(userId).once();

        if (deptSnapshot.snapshot.exists) {
          final deptData = Map<String, dynamic>.from(
              deptSnapshot.snapshot.value as Map);

          setState(() {
            _departmentName = deptData['name']?.toString();
            _departmentWard = deptData['wardno']?.toString();
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Department details not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Department ID not provided';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error fetching department details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchComplaints() async {
    try {
      final complaintsSnapshot = await _complaintsRef.once();

      if (complaintsSnapshot.snapshot.value != null) {
        final rawData = Map<String, dynamic>.from(
            complaintsSnapshot.snapshot.value as Map);

        List<Map<String, dynamic>> tempComplaints = [];

        for (var entry in rawData.entries) {
          final complaintData = Map<String, dynamic>.from(entry.value as Map);
          complaintData['key'] = entry.key;


          final citizenWard = complaintData['citizenWard']?.toString();
          final forwardedTo = complaintData['forwardedTo']?.toString();
          final status = complaintData['status']?.toString();


          if (status == 'forwarded' &&
              citizenWard == _departmentWard &&
              forwardedTo == _departmentName) {
            tempComplaints.add(complaintData);


            if (!_showCompletionDialog.containsKey(complaintData['key'])) {
              _showCompletionDialog[complaintData['key']] = false;
              _completionNotes[complaintData['key']] = '';
              _completionImages[complaintData['key']] = null;
              _uploadingProof[complaintData['key']] = false;
            }
          }
        }


        tempComplaints.sort((a, b) {
          final timeA = DateTime.parse(a['forwardedDate'] ?? a['timestamp'] ?? '2000-01-01');
          final timeB = DateTime.parse(b['forwardedDate'] ?? b['timestamp'] ?? '2000-01-01');
          return timeB.compareTo(timeA);
        });

        setState(() {
          _allComplaints = tempComplaints;
          _filteredComplaints = tempComplaints;
          _isLoading = false;
        });
      } else {
        setState(() {
          _allComplaints = [];
          _filteredComplaints = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading complaints: $e';
        _isLoading = false;
      });
    }
  }

  void _applySearchFilter() {
    if (searchQuery.isEmpty) {
      setState(() {
        _filteredComplaints = List.from(_allComplaints);
      });
      return;
    }

    final query = searchQuery.toLowerCase();
    setState(() {
      _filteredComplaints = _allComplaints.where((complaint) {
        final complaintText = (complaint['complaint'] ?? '').toString().toLowerCase();
        final complaintType = (complaint['complaintType'] ?? '').toString().toLowerCase();
        final location = (complaint['tenderLoc'] ?? '').toString().toLowerCase();
        final tenderName = (complaint['tenderName'] ?? '').toString().toLowerCase();

        return complaintText.contains(query) ||
            complaintType.contains(query) ||
            location.contains(query) ||
            tenderName.contains(query);
      }).toList();
    });
  }

  Future<void> _updateComplaintStatus(String complaintKey, String newStatus) async {
    try {
      await _complaintsRef.child(complaintKey).update({
        'status': newStatus,
        'departmentActionDate': DateTime.now().toIso8601String(),
        'actionTakenByDepartment': _departmentName,
      });


      final index = _allComplaints.indexWhere((c) => c['key'] == complaintKey);
      if (index != -1) {
        setState(() {
          _allComplaints[index]['status'] = newStatus;
          _allComplaints[index]['departmentActionDate'] = DateTime.now().toIso8601String();
          _allComplaints[index]['actionTakenByDepartment'] = _departmentName;
        });
        _applySearchFilter();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint marked as $newStatus'),
          backgroundColor: Colors.green,
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

  Future<void> _showCompletionProofDialog(String complaintKey) async {
    setState(() {
      _showCompletionDialog[complaintKey] = true;
    });
  }

  Future<void> _cancelCompletion(String complaintKey) async {

    final oldImage = _completionImages[complaintKey];
    if (oldImage != null) {
      await oldImage.delete();
    }

    setState(() {
      _showCompletionDialog[complaintKey] = false;
      _completionNotes[complaintKey] = '';
      _completionImages[complaintKey] = null;
    });
  }

  Future<void> _pickCompletionImage(String complaintKey) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (pickedFile != null) {

        final oldImage = _completionImages[complaintKey];
        if (oldImage != null) {
          await oldImage.delete();
        }

        setState(() {
          _completionImages[complaintKey] = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeCompletionImage(String complaintKey) async {
    final imageFile = _completionImages[complaintKey];
    if (imageFile != null) {
      await imageFile.delete();
    }

    setState(() {
      _completionImages[complaintKey] = null;
    });
  }

  Future<String?> _uploadCompletionProof(String complaintKey) async {
    final imageFile = _completionImages[complaintKey];
    if (imageFile == null) return null;

    try {
      final fileName = 'completion_proof_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storageRef = _storage.ref().child('completion_proofs/$fileName');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => {});

      if (snapshot.state == TaskState.success) {
        final downloadURL = await storageRef.getDownloadURL();
        return downloadURL;
      }
      return null;
    } catch (e) {
      print('Error uploading proof: $e');
      return null;
    }
  }

  Future<void> _markAsCompleted(String complaintKey) async {

    final notes = _completionNotes[complaintKey]?.trim() ?? '';
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add completion notes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _uploadingProof[complaintKey] = true;
    });

    try {

      String? proofImageUrl;
      final imageFile = _completionImages[complaintKey];
      if (imageFile != null) {
        proofImageUrl = await _uploadCompletionProof(complaintKey);
      }


      final completionData = {
        'status': 'completed',
        'completionDate': DateTime.now().toIso8601String(),
        'completedByDepartment': _departmentName,
        'completionNotes': notes,
        'completionProofImage': proofImageUrl,
        'departmentActionDate': DateTime.now().toIso8601String(),
        'actionTakenByDepartment': _departmentName,
      };


      await _complaintsRef.child(complaintKey).update(completionData);


      final index = _allComplaints.indexWhere((c) => c['key'] == complaintKey);
      if (index != -1) {
        setState(() {
          _allComplaints[index].addAll(completionData);
          _showCompletionDialog[complaintKey] = false;
          _completionNotes[complaintKey] = '';
          _completionImages[complaintKey] = null;
          _applySearchFilter();
        });
      }


      if (imageFile != null) {
        await imageFile.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint marked as completed with proof'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking as completed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _uploadingProof[complaintKey] = false;
      });
    }
  }

  Widget _buildCompletionProofSection(Map<String, dynamic> complaint) {
    final complaintKey = complaint['key'];
    final showDialog = _showCompletionDialog[complaintKey] ?? false;
    final imageFile = _completionImages[complaintKey];
    final isUploading = _uploadingProof[complaintKey] ?? false;

    if (!showDialog) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.task_alt, color: Colors.green[800], size: 24),
              SizedBox(width: 8),
              Text(
                'Completion Proof',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: isUploading ? null : () => _cancelCompletion(complaintKey),
                icon: Icon(Icons.close, color: Colors.grey[600]),
                tooltip: 'Cancel',
              ),
            ],
          ),
          SizedBox(height: 12),


          Text(
            'Provide proof of completion to mark this complaint as resolved',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),


          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Completion Proof (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              if (imageFile == null)
                ElevatedButton.icon(
                  onPressed: isUploading ? null : () => _pickCompletionImage(complaintKey),
                  icon: Icon(Icons.camera_alt, size: 20),
                  label: Text('Add Photo Proof'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[100],
                    foregroundColor: Colors.blueGrey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                )
              else
                Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: isUploading ? null : () => _pickCompletionImage(complaintKey),
                          icon: Icon(Icons.edit, size: 18),
                          label: Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueGrey[900],
                          ),
                        ),
                        SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: isUploading ? null : () => _removeCompletionImage(complaintKey),
                          icon: Icon(Icons.delete, size: 18, color: Colors.red),
                          label: Text('Remove'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 16),


          TextFormField(
            onChanged: (value) {
              _completionNotes[complaintKey] = value;
            },
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Completion Notes *',
              hintText: 'Describe what work was completed...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter completion notes';
              }
              return null;
            },
          ),
          SizedBox(height: 20),


          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : () => _markAsCompleted(complaintKey),
              icon: isUploading
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Icon(Icons.check_circle, size: 22),
              label: Text(
                isUploading ? 'Uploading Proof...' : 'Mark as Completed',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewImage(String imageUrl) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Image'),
            backgroundColor: Colors.blueGrey[900],
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

  Future<void> _viewCompletionProof(String imageUrl) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Completion Proof'),
            backgroundColor: Colors.green[700],
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

  Widget _buildLoadingState() {
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
            'Loading Complaints...',
            style: TextStyle(
              color: Colors.blueGrey[800],
              fontSize: 16,
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
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _initializeData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[900],
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
            Icons.inbox,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No Forwarded Complaints',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            _departmentName != null
                ? 'No complaints forwarded to $_departmentName for ward $_departmentWard'
                : 'No forwarded complaints available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _initializeData,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[900],
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
          colors: [Colors.blueGrey[900]!, Colors.blueGrey[800]!],
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
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.report_problem,
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
                      _departmentName ?? 'Department',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Forwarded Complaints',
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
                value: _allComplaints.length.toString(),
                label: 'Total Complaints',
                icon: Icons.receipt,
              ),
              _buildStatCard(
                value: _allComplaints.where((c) => c['status'] == 'completed').length.toString(),
                label: 'Completed',
                icon: Icons.check_circle,
              ),
              _buildStatCard(
                value: _departmentWard ?? 'N/A',
                label: 'Ward',
                icon: Icons.location_on,
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

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final hasImage = complaint['imageUrl'] != null &&
        (complaint['imageUrl'] as String).isNotEmpty;
    final hasCompletionProof = complaint['completionProofImage'] != null &&
        (complaint['completionProofImage'] as String).isNotEmpty;
    final status = complaint['status'] ?? 'forwarded';
    final priority = complaint['priority'] ?? 'low';
    final isCompleted = status == 'completed';
    final isEven = _allComplaints.indexOf(complaint) % 2 == 0;

    return Container(
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
          color: isCompleted ? Colors.green[100]! : Colors.blueGrey[100]!,
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
                    color: isCompleted ? Colors.green[700]! : Colors.blueGrey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.gavel,
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
                        complaint['complaintType'] ?? 'General Complaint',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green[900] : Colors.blueGrey[900],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Forwarded on: ${complaint['forwardedDate']?.toString().substring(0, 10) ?? complaint['formattedDate'] ?? 'Unknown Date'}',
                        style: TextStyle(
                          color: isCompleted ? Colors.green[700] : Colors.blueGrey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),


            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),


            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDetailCard(
                  Icons.person,
                  'Citizen',
                  complaint['name'] ?? 'N/A',
                  Colors.blueGrey,
                ),
                _buildDetailCard(
                  Icons.location_on,
                  'Location',
                  complaint['tenderLoc'] ?? 'N/A',
                  Colors.blueAccent,
                ),
                _buildDetailCard(
                  Icons.assignment,
                  'Related Tender',
                  complaint['tenderName'] ?? 'N/A',
                  Colors.deepOrange,
                ),
                _buildDetailCard(
                  Icons.location_city,
                  'Citizen Ward',
                  complaint['citizenWard'] ?? 'N/A',
                  Colors.indigo,
                ),
              ],
            ),
            SizedBox(height: 16),


            if (isCompleted)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.task_alt, color: Colors.green[800], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Completed Information',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[900],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Completed on: ${complaint['completionDate']?.toString().substring(0, 10) ?? 'Unknown Date'}',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    if (complaint['completionNotes'] != null && (complaint['completionNotes'] as String).isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            complaint['completionNotes']!,
                            style: TextStyle(
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 12),
                    if (hasCompletionProof)
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _viewCompletionProof(complaint['completionProofImage']!),
                            icon: Icon(Icons.image, size: 18),
                            label: Text('View Completion Proof'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                              foregroundColor: Colors.green[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
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
                        color: Colors.blueGrey[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Complaint Description',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    complaint['complaint'] ?? 'No description provided',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),


            if (hasImage)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  SizedBox(height: 12),
                  Text(
                    'Original Complaint Image',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () => _viewImage(complaint['imageUrl']!),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueGrey[100]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[900],
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
                            child: Text(
                              'Click to view complaint image',
                              style: TextStyle(
                                color: Colors.blueGrey[700],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.blueGrey[900],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),


            if (!isCompleted)
              _buildCompletionProofSection(complaint),


            if (!isCompleted && !(_showCompletionDialog[complaint['key']] ?? false))
              Column(
                children: [
                  Divider(),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCompletionProofDialog(complaint['key']),
                          icon: Icon(Icons.task_alt, size: 20),
                          label: Text('Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateComplaintStatus(complaint['key'], 'in_progress'),
                          icon: Icon(Icons.build, size: 20),
                          label: Text('Mark in Progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: 8),
          Expanded(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'forwarded':
        return Colors.blueGrey;
      case 'resolved':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.build;
      case 'forwarded':
        return Icons.forward;
      case 'resolved':
        return Icons.check;
      default:
        return Icons.pending;
    }
  }

  Widget _buildComplaintListView() {
    if (_filteredComplaints.isEmpty) {
      return Center(
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
                  ? 'No Forwarded Complaints'
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
                  ? 'No complaints forwarded to your department'
                  : 'Try different search terms',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: _filteredComplaints.length,
      itemBuilder: (context, index) {
        return _buildComplaintCard(_filteredComplaints[index]);
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
            builder: (context) => DepartmentHome(),
          ),
        );
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey[50],
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
                              hintText: 'Search by complaint type, location, or tender name...',
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
                                _applySearchFilter();
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
                                _applySearchFilter();
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
                        color: Colors.blueGrey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blueGrey[900]),
                          SizedBox(width: 6),
                          Text(
                            'Showing forwarded complaints for $_departmentName (Ward: $_departmentWard)',
                            style: TextStyle(
                              color: Colors.blueGrey[900],
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


              if (!_isLoading && !_hasError && _allComplaints.isNotEmpty)
                _buildHeader(),

              SizedBox(height: 8),


              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasError
                    ? _buildErrorState()
                    : _allComplaints.isEmpty
                    ? _buildEmptyState()
                    : _buildComplaintListView(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _initializeData,
          icon: Icon(Icons.refresh),
          label: Text('Refresh'),
          backgroundColor: Colors.blueGrey[900],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}