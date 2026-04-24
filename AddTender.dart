import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';

class AddTenderDetails extends StatefulWidget {
  const AddTenderDetails({Key? key}) : super(key: key);

  @override
  _AddTenderDetailsState createState() => _AddTenderDetailsState();
}

class _AddTenderDetailsState extends State<AddTenderDetails> {
  final _formKey = GlobalKey<FormState>();
  String tenderName = '';
  String tenderEmail = '';
  String description = '';
  String location = '';
  String amount = '';
  String department = '';
  String? documentPath;
  String formKey = '';
  bool _isSubmitting = false;
  bool _isUploading = false;

  final DatabaseReference _tenderRef = FirebaseDatabase.instance.ref('tenders');

  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (documentPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload a project document'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        formKey = DateTime.now().millisecondsSinceEpoch.toString();

        await _tenderRef.child(formKey).set({
          'tenderName': tenderName,
          'contactmail': tenderEmail,
          'description': description,
          'location': location,
          'department': department,
          'amount': amount,
          'documentPath': documentPath,
          'status': 'request',
          'formKey': formKey,
          'timestamp': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Tender Submitted Successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );


        _formKey.currentState!.reset();
        setState(() {
          documentPath = null;
          formKey = '';
          _isSubmitting = false;
        });


        _showSuccessDialog();

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> pickDocument() async {
    setState(() {
      _isUploading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null) {
        String filePath = result.files.single.path!;
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';

        Reference ref = FirebaseStorage.instance.ref().child('documents/$fileName');
        UploadTask uploadTask = ref.putFile(File(filePath));

        TaskSnapshot snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          documentPath = downloadUrl;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white),
                SizedBox(width: 10),
                Text('Document Uploaded Successfully'),
              ],
            ),
            backgroundColor: Colors.teal[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Bounce(
              duration: Duration(seconds: 2),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Success!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),
          ],
        ),
        content: Text(
          'Tender details have been successfully submitted and are now under review.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Continue', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: FadeInUp(
                duration: Duration(milliseconds: 600),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: Colors.teal.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.teal[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.teal[100]!, width: 2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.teal[900],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.gavel,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'New Tender Submission',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal[900],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Fill in the details below to create a new tender',
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
                              ),
                              SizedBox(height: 8),
                              Text(
                                'All fields are required for submission',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),


                          Form(
                            key: _formKey,
                            child: Column(
                              children: [

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextFieldWithIcon(
                                        'Tender Name',
                                        Icons.badge,
                                            (value) => tenderName = value,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextFieldWithIcon(
                                        'Department',
                                        Icons.business,
                                            (value) => department = value,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),


                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextFieldWithIcon(
                                        'Contact Email',
                                        Icons.email,
                                            (value) => tenderEmail = value,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextFieldWithIcon(
                                        'Location',
                                        Icons.location_on,
                                            (value) => location = value,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),


                                _buildTextFieldWithIcon(
                                  'Amount (₹)',
                                  Icons.currency_rupee,
                                      (value) => amount = value,
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: 20),


                                _buildTextAreaField(
                                  'Description',
                                      (value) => description = value,
                                ),
                                SizedBox(height: 20),


                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: documentPath != null ? Colors.green : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.description,
                                            color: Colors.teal[700],
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Project Document',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.teal[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Upload project document (PDF, DOC, DOCX)',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      SizedBox(height: 16),
                                      if (documentPath != null)
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green[100]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green, size: 24),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Document uploaded successfully',
                                                  style: TextStyle(color: Colors.green[800]),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    documentPath = null;
                                                  });
                                                },
                                                icon: Icon(Icons.close, color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ),
                                      SizedBox(height: documentPath != null ? 16 : 0),
                                      ElevatedButton.icon(
                                        onPressed: _isUploading ? null : pickDocument,
                                        icon: _isUploading
                                            ? SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                            : Icon(Icons.cloud_upload),
                                        label: Text(_isUploading ? 'Uploading...' : 'Choose File'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal[700],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 30),


                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal[900],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.teal.withOpacity(0.5),
                                    ),
                                    onPressed: _isSubmitting ? null : submitForm,
                                    child: _isSubmitting
                                        ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Submitting...'),
                                      ],
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send, size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'SUBMIT TENDER',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithIcon(
      String label,
      IconData icon,
      Function(String) onChanged, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return FadeInLeft(
      duration: Duration(milliseconds: 400),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextAreaField(String label, Function(String) onChanged) {
    return FadeInLeft(
      duration: Duration(milliseconds: 400),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Icon(Icons.description, color: Colors.teal[700]),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(16, 20, 16, 20),
        ),
        maxLines: 4,
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
        onChanged: onChanged,
      ),
    );
  }
}