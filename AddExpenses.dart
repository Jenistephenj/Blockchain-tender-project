import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart' as web3;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:web_socket_channel/io.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';

class ExpenseDetailsPage extends StatefulWidget {
  final String? tenderId;
  final String? tenderName;

  const ExpenseDetailsPage({
    Key? key,
    this.tenderId,
    this.tenderName,
  }) : super(key: key);

  @override
  _ExpenseDetailsPageState createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  final String _rpcURL = "http://10.138.185.218:7545";
  final String _wsURL = "ws://10.138.185.218:7545/";
  final String _privateKey = "0x3607d1413d2d426bb3aa22d3bf376442222434691c581352b5458a45c7332283";

  late web3.Web3Client _client;
  late String _abiCode;
  late web3.EthereumAddress _contractAddress;
  late web3.Credentials _credentials;
  late web3.DeployedContract _contract;
  late web3.ContractFunction _setNameFunction;

  int _transactionCount = 0;
  bool _isSubmitting = false;
  String _lastTransactionHash = '';
  String _connectionStatus = 'Connecting...';
  String _blockchainError = '';

  late RSAPublicKey publicKey;
  late RSAPrivateKey privateKey;

  File? _selectedFile;
  String? _fileName;
  String? _fileSize;
  bool _isUploadingFile = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  TextEditingController amount = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController location = TextEditingController();
  TextEditingController mobile = TextEditingController();

  @override
  void initState() {
    super.initState();
    generateKeyPair();
    initialSetup();
  }

  Future<void> initialSetup() async {
    try {
      setState(() {
        _connectionStatus = 'Connecting to blockchain...';
      });

      _client = web3.Web3Client(_rpcURL, http.Client(),
          socketConnector: () => IOWebSocketChannel.connect(_wsURL).cast<String>());

      final clientVersion = await _client.getClientVersion();
      print("Connected to: $clientVersion");

      await getAbi();
      await getCredentials();
      await getDeployedContract();
      await _getTransactionCount();

      setState(() {
        _connectionStatus = 'Connected to Ganache';
      });

    } catch (e) {
      print("Error initializing Ethereum client: $e");
      setState(() {
        _connectionStatus = 'Connection failed';
        _blockchainError = e.toString();
      });
    }
  }

  Future<void> getAbi() async {
    try {
      String abiStringFile = await rootBundle.loadString("src/artifacts/HelloWorld.json");
      var jsonAbi = jsonDecode(abiStringFile);
      _abiCode = jsonEncode(jsonAbi["abi"]);
      _contractAddress = web3.EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
      print("Contract address: $_contractAddress");
    } catch (e) {
      print("Error loading ABI: $e");
      throw Exception("ABI loading failed: $e");
    }
  }

  Future<void> getDeployedContract() async {
    try {
      _contract = web3.DeployedContract(
          web3.ContractAbi.fromJson(_abiCode, "HelloWorld"), _contractAddress);
      _setNameFunction = _contract.function("setName");
      print("Contract deployed successfully");
    } catch (e) {
      print("Error deploying contract: $e");
      throw Exception("Contract deployment failed: $e");
    }
  }

  Future<void> getCredentials() async {
    try {
      _credentials = web3.EthPrivateKey.fromHex(_privateKey);
      final address = await _credentials.extractAddress();
      print("Using account: $address");

      final balance = await _client.getBalance(address);
      print("Account balance: ${balance.getValueInUnit(web3.EtherUnit.ether)} ETH");

    } catch (e) {
      print("Error loading private key: $e");
      throw Exception("Credentials failed: $e");
    }
  }

  Future<void> _getTransactionCount() async {
    try {
      final address = await _credentials.extractAddress();
      final count = await _client.getTransactionCount(address);
      print("Current transaction count: $count");
      setState(() {
        _transactionCount = count;
      });
    } catch (e) {
      print("Error getting transaction count: $e");
      setState(() {
        _blockchainError = "Tx count error: $e";
      });
    }
  }

  Future<void> _executeBlockchainTransaction(String data) async {
    try {
      print("Calling setName with: $data");

      final transaction = web3.Transaction.callContract(
        contract: _contract,
        function: _setNameFunction,
        parameters: [data],
        maxGas: 100000,
      );

      print("Sending transaction...");

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: 1337,
      );

      print("Transaction sent successfully: $txHash");
      setState(() {
        _lastTransactionHash = txHash;
        _blockchainError = '';
      });

      await Future.delayed(Duration(seconds: 2));

      await _getTransactionCount();

    } catch (e) {
      print("Error executing blockchain transaction: $e");
      setState(() {
        _blockchainError = "Transaction failed: $e";
      });
      throw e;
    }
  }

  void generateKeyPair() {
    var pair = CryptoUtils.generateRSAKeyPair();
    publicKey = pair.publicKey as RSAPublicKey;
    privateKey = pair.privateKey as RSAPrivateKey;
  }

  String encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey, privateKey: privateKey));
    return encrypter.encrypt(data).base64;
  }

  String generateBlindSignature(String data) {
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        double fileSizeInKB = result.files.single.size / 1024;

        setState(() {
          _selectedFile = file;
          _fileName = fileName;
          _fileSize = fileSizeInKB < 1024
              ? '${fileSizeInKB.toStringAsFixed(1)} KB'
              : '${(fileSizeInKB / 1024).toStringAsFixed(1)} MB';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: $fileName'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadFile(String dataKey) async {
    if (_selectedFile == null) return null;

    try {
      setState(() {
        _isUploadingFile = true;
      });

      String fileExtension = _selectedFile!.path.split('.').last.toLowerCase();
      String fileName = "expense_proof_${DateTime.now().millisecondsSinceEpoch}.$fileExtension";


      Reference storageReference = _storage.ref().child('expense_proofs/$dataKey/$fileName');


      UploadTask uploadTask = storageReference.putFile(_selectedFile!);


      TaskSnapshot snapshot = await uploadTask;


      String downloadUrl = await snapshot.ref.getDownloadURL();

      print("File uploaded successfully: $downloadUrl");

      setState(() {
        _isUploadingFile = false;
      });

      return downloadUrl;
    } catch (e) {
      print("Error uploading file: $e");
      setState(() {
        _isUploadingFile = false;
      });
      throw Exception("File upload failed: $e");
    }
  }

  Future<void> fetchData() async {
    if (amount.text.isEmpty || description.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in required fields (Amount & Description)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _blockchainError = '';
    });

    try {
      User? user = _auth.currentUser;
      String? userId = user?.uid;
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch;


      String encryptedAmount = encryptData(amount.text.trim());
      String encryptedDescription = encryptData(description.text.trim());
      String encryptedLocation = encryptData(location.text.trim());
      String encryptedMobile = encryptData(mobile.text.trim());


      String blindSignature = generateBlindSignature(
          encryptedAmount + encryptedDescription + encryptedLocation + encryptedMobile
      );

      String dataKey = _database.child('expense').push().key ?? '';


      print("Starting blockchain transaction...");
      String combinedData = '${amount.text},${mobile.text},${description.text}';
      await _executeBlockchainTransaction(combinedData);
      print("Blockchain transaction completed");


      String? fileUrl;
      if (_selectedFile != null) {
        fileUrl = await _uploadFile(dataKey);
      }


      Map<String, dynamic> expenseData = {
        'description': description.text.trim(),
        'amount': amount.text.trim(),
        'location': location.text.trim(),
        'mobile': mobile.text.trim(),
        'tenderId': widget.tenderId,
        'tenderName': widget.tenderName,
        'timestamp': currentTimestamp,
        'status1': 'request',
        'status2': 'request',
        'date': formattedDate,
        'uid': userId,
        'datakey': dataKey,
        'blind_signature': blindSignature,
        'blockchain_tx_hash': _lastTransactionHash,
        'blockchain_tx_count': _transactionCount,
      };


      if (fileUrl != null) {
        expenseData['file_proof_url'] = fileUrl;
        expenseData['file_name'] = _fileName;
        expenseData['file_size'] = _fileSize;
      }

      await _database.child('expense').child(dataKey).set(expenseData);


      Map<String, dynamic> secretData = {
        'combinedData': combinedData,
        'encryptedAmount': encryptedAmount,
        'encryptedDescription': encryptedDescription,
        'encryptedLocation': encryptedLocation,
        'encryptedMobile': encryptedMobile,
        'blind_signature': blindSignature,
        'transactionHash': _lastTransactionHash,
        'timestamp': currentTimestamp,
        'status1': 'request',
        'status2': 'request',
        'date': formattedDate,
        'uid': userId,
        'datakey': dataKey,
        'transactionCount': _transactionCount,
      };


      if (fileUrl != null) {
        secretData['file_proof_url'] = fileUrl;
        secretData['file_name'] = _fileName;
        secretData['file_hash'] = generateBlindSignature(fileUrl); // Hash of file URL for verification
      }

      await _database.child('blockchaininfo').child(dataKey).set(secretData);


      description.clear();
      location.clear();
      amount.clear();
      mobile.clear();
      setState(() {
        _selectedFile = null;
        _fileName = null;
        _fileSize = null;
      });

      _showSuccessDialog(fileUrl != null);

    } catch (e) {
      print("Error submitting expense: $e");
      setState(() {
        _blockchainError = e.toString();
      });
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _testBlockchainConnection() async {
    try {
      setState(() {
        _connectionStatus = 'Testing connection...';
        _blockchainError = '';
      });

      final clientVersion = await _client.getClientVersion();
      final address = await _credentials.extractAddress();
      final balance = await _client.getBalance(address);
      final count = await _client.getTransactionCount(address);

      setState(() {
        _connectionStatus = 'Connected to: $clientVersion';
        _transactionCount = count;
        _blockchainError = 'Balance: ${balance.getValueInUnit(web3.EtherUnit.ether)} ETH';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection successful! Balance: ${balance.getValueInUnit(web3.EtherUnit.ether)} ETH'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed';
        _blockchainError = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(bool hasFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text(
              "Success!",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Expense submitted successfully!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 10),
            if (hasFile)
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_file, color: Colors.teal, size: 16),
                      SizedBox(width: 5),
                      Text(
                        "File proof uploaded",
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            Text(
              "Transaction Hash:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _lastTransactionHash));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Transaction hash copied to clipboard"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _lastTransactionHash.substring(0, 20) + "...",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ),
                    Icon(Icons.copy, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, color: Colors.teal[700], size: 16),
                SizedBox(width: 5),
                Text(
                  "Data stored on blockchain",
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(
                color: Colors.teal[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 10),
            Text(
              "Error!",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          error.length > 200 ? error.substring(0, 200) + "..." : error,
          style: TextStyle(
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _connectionStatus.contains('Connected')
              ? Colors.green.withOpacity(0.5)
              : Colors.red.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _connectionStatus.contains('Connected') ? Icons.check_circle : Icons.error,
            color: _connectionStatus.contains('Connected') ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _connectionStatus,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCounter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.teal.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Blockchain Transactions:',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              Text(
                '$_transactionCount',
                style: TextStyle(
                  color: Colors.teal[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_lastTransactionHash.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Last Tx: ${_lastTransactionHash.substring(0, 16)}...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
          if (_blockchainError.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              _blockchainError,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Expense Proof',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.teal[700],
              ),
            ),
          ),
          GestureDetector(
            onTap: _isSubmitting || _isUploadingFile ? null : _pickFile,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFile != null ? Colors.teal : Colors.teal.shade100,
                  width: _selectedFile != null ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  if (_selectedFile != null)
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getFileIcon(),
                              color: Colors.teal[700],
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fileName ?? 'Selected File',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _fileSize ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: _isSubmitting || _isUploadingFile
                                  ? null
                                  : () {
                                setState(() {
                                  _selectedFile = null;
                                  _fileName = null;
                                  _fileSize = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (_isUploadingFile)
                          LinearProgressIndicator(
                            backgroundColor: Colors.teal.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[700]!),
                          ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          color: Colors.teal[700],
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload Receipt/Proof',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.teal[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to upload PDF, JPG, PNG, DOC files',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    if (_fileName == null) return Icons.insert_drive_file;

    String extension = _fileName!.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal[700],
        elevation: 4,
        title: Text(
          'Expense Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _testBlockchainConnection,
            tooltip: "Refresh Connection",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildConnectionStatus(),
            SizedBox(height: 16),


            _buildTransactionCounter(),
            SizedBox(height: 24),


            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Expense',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fill in the details below to submit an expense',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),


            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: amount,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.currency_rupee,
                    color: Colors.teal[700],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.teal.shade100, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                  ),
                  hintText: 'Enter amount in rupees',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  suffixText: '₹',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),


            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: description,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  labelStyle: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.description,
                    color: Colors.teal[700],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.teal.shade100, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                  ),
                  hintText: 'Enter expense description (required)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  alignLabelWithHint: true,
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),


            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: location,
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: Colors.teal[700],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.teal.shade100, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                  ),
                  hintText: 'Enter location where expense occurred',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),


            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: mobile,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  labelStyle: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.phone,
                    color: Colors.teal[700],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.teal.shade100, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                  ),
                  hintText: 'Enter your mobile number',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixText: '+91 ',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),


            _buildFileUploadSection(),
            SizedBox(height: 32),


            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: _connectionStatus.contains('Connected')
                ? [Colors.teal[700]!, Colors.teal.shade700]
                : [Colors.grey.shade400, Colors.grey.shade600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _connectionStatus.contains('Connected')
                  ? Colors.teal[700]!.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isSubmitting || !_connectionStatus.contains('Connected')
                ? null
                : fetchData,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting || _isUploadingFile)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      _connectionStatus.contains('Connected')
                          ? Icons.cloud_upload
                          : Icons.cloud_off,
                      color: Colors.white,
                    ),
                  SizedBox(width: 12),
                  Text(
                    _isSubmitting || _isUploadingFile
                        ? 'Submitting...'
                        : (_connectionStatus.contains('Connected')
                        ? 'Submit Expense'
                        : 'Connect to Ganache'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}