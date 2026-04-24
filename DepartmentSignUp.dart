import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'DepartmentLogin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    home: DepartmentSignUp(),
  ));
}

class DepartmentSignUp extends StatefulWidget {
  DepartmentSignUp({Key? key}) : super(key: key);

  @override
  _DepartmentSignUpState createState() => _DepartmentSignUpState();
}

class _DepartmentSignUpState extends State<DepartmentSignUp> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController wardnoController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController districtController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        String? userId = userCredential.user?.uid;
        Map<String, dynamic> userData = {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'mobile': mobileController.text.trim(),
          'wardno': wardnoController.text.trim(),
          'location': locationController.text.trim(),
          'district': districtController.text.trim(),
          'ukey': userId,
          'registrationDate': DateTime.now().toIso8601String(),
          'departmentType': 'government',
          'status': 'pending_verification',
        };

        await _database.child('Department').child(userId!).set(userData);
        await sendVerificationEmail();


        _showSuccessDialog();
      } catch (e) {
        _showErrorDialog(e.toString());
      }
      setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1A5F7A),
                      Color(0xFF2D936C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 25),
              Text(
                'Registration Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A5F7A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Your department registration has been submitted for review. A verification email has been sent to your registered email address.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D6D7E),
                  height: 1.6,
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DepartmentLogin()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A5F7A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'PROCEED TO LOGIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.redAccent,
              ),
              SizedBox(height: 20),
              Text(
                'Registration Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 15),
              Text(
                error.replaceAll('FirebaseAuthException:', ''),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5D6D7E),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A5F7A),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('RETRY'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF0F4F8),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        SizedBox(height: 30),


                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF1A5F7A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.account_balance_rounded,
                                size: 32,
                                color: Color(0xFF1A5F7A),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Department Registration',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A5F7A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Register your government department to manage tenders transparently',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF5D6D7E),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),


                        SizedBox(height: 40),


                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 30,
                                offset: Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Column(
                                children: [

                                  _buildSectionHeader('Department Details'),
                                  SizedBox(height: 25),


                                  _buildTextField(
                                    controller: nameController,
                                    label: 'Department Name',
                                    icon: Icons.account_balance_outlined,
                                    hint: 'Enter department name',
                                    validator: (value) => value!.isEmpty ? 'Enter department name' : null,
                                  ),

                                  SizedBox(height: 20),


                                  _buildTextField(
                                    controller: emailController,
                                    label: 'Official Email',
                                    icon: Icons.email_outlined,
                                    hint: 'department@government.gov',
                                    keyboardType: TextInputType.emailAddress,

                                  ),

                                  SizedBox(height: 20),


                                  _buildPasswordField(
                                    controller: passwordController,
                                    label: 'Secure Password',
                                    hint: 'Create a strong password',
                                  ),

                                  SizedBox(height: 30),


                                  _buildSectionHeader('Contact Information'),
                                  SizedBox(height: 25),


                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: mobileController,
                                          label: 'Contact Number',
                                          icon: Icons.phone_outlined,
                                          hint: '10-digit mobile number',
                                          keyboardType: TextInputType.phone,
                                          validator: (value) {
                                            if (value!.isEmpty) return 'Enter contact number';
                                            if (value.length != 10) return 'Enter valid 10-digit number';
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: wardnoController,
                                          label: 'Ward Number',
                                          icon: Icons.numbers_outlined,
                                          hint: 'Ward no.',
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 20),


                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: locationController,
                                          label: 'Location',
                                          icon: Icons.location_on_outlined,
                                          hint: 'City/Town',
                                          validator: (value) => value!.isEmpty ? 'Enter location' : null,
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: districtController,
                                          label: 'District',
                                          icon: Icons.map_outlined,
                                          hint: 'District name',
                                          validator: (value) => value!.isEmpty ? 'Enter district' : null,
                                        ),
                                      ),
                                    ],
                                  ),



                                  SizedBox(height: 40),


                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF1A5F7A),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        elevation: 2,
                                        shadowColor: Color(0xFF1A5F7A).withOpacity(0.3),
                                      ),
                                      child: isLoading
                                          ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                          : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.how_to_reg_rounded, size: 22),
                                          SizedBox(width: 12),
                                          Text(
                                            'REGISTER DEPARTMENT',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 25),


                                  Center(
                                    child: TextButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => DepartmentLogin()),
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(fontSize: 14),
                                          children: [
                                            TextSpan(
                                              text: 'Already registered? ',
                                              style: TextStyle(
                                                color: Color(0xFF5D6D7E),
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'Login Here',
                                              style: TextStyle(
                                                color: Color(0xFF1A5F7A),
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                                decorationThickness: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 30),


                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Color(0xFF1A5F7A).withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: Color(0xFF2D936C),
                                size: 24,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Secure Registration',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'All department registrations undergo verification for authenticity and security compliance.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5D6D7E),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          height: 28,
          width: 5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A5F7A), Color(0xFF2D936C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 15),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: Color(0xFF2C3E50),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        labelStyle: TextStyle(
          color: Color(0xFF5D6D7E),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.only(right: 15, left: 5),
          decoration: BoxDecoration(
            color: Color(0xFF1A5F7A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Color(0xFF1A5F7A),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF1A5F7A), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePassword,
      validator: (value) {
        if (value!.isEmpty) return 'Enter password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      style: TextStyle(
        fontSize: 16,
        color: Color(0xFF2C3E50),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        labelStyle: TextStyle(
          color: Color(0xFF5D6D7E),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.only(right: 15, left: 5),
          decoration: BoxDecoration(
            color: Color(0xFF1A5F7A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(12),
          child: Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF1A5F7A),
            size: 20,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Color(0xFF5D6D7E),
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF1A5F7A), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}