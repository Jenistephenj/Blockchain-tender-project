import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tender/user/UserLogin.dart';

class UserSignUp extends StatefulWidget {
  @override
  _UserSignUpState createState() => _UserSignUpState();
}

class _UserSignUpState extends State<UserSignUp> with SingleTickerProviderStateMixin {
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

        User? user = userCredential.user;
        String? userId = user?.uid;

        Map<String, dynamic> userData = {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'mobile': mobileController.text.trim(),
          'wardno': wardnoController.text.trim(),
          'location': locationController.text.trim(),
          'district': districtController.text.trim(),
          'ukey': userId,
          'registrationDate': DateTime.now().toIso8601String(),
          'userType': 'citizen',
          'status': 'active',
        };

        await _database.child('Users').child(userId!).set(userData);
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
                      Color(0xFF2D936C),
                      Color(0xFF1A5F7A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 25),
              Text(
                'Welcome Aboard!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A5F7A),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Your citizen account has been created successfully. You can now track government tenders and submit feedback.',
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
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => UserLogin()),
                        (route) => false,
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
                    'START EXPLORING TENDERS',
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
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 15),
              Text(
                error.replaceAll('FirebaseAuthException:', '').trim(),
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
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('TRY AGAIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
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
          backgroundColor: Color(0xFFF8F9FA),
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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Public Portal Registration',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A5F7A),
                              ),
                            ),
                          ],
                        ),


                        SizedBox(height: 30),


                        Container(
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A5F7A).withOpacity(0.1),
                                Color(0xFF2D936C).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.groups_rounded,
                                  size: 32,
                                  color: Color(0xFF1A5F7A),
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Become a Civic Participant',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A5F7A),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Track government tenders, monitor progress, and contribute to transparent governance.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF5D6D7E),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [

                                  _buildSectionHeader('Personal Information'),
                                  SizedBox(height: 25),


                                  _buildTextField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline_rounded,
                                    hint: 'Enter your full name',
                                    validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                                  ),

                                  SizedBox(height: 20),


                                  _buildTextField(
                                    controller: emailController,
                                    label: 'Email Address',
                                    icon: Icons.email_outlined,
                                    hint: 'your.email@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                  ),

                                  SizedBox(height: 20),


                                  _buildPasswordField(
                                    controller: passwordController,
                                    label: 'Password',
                                    hint: 'Create a secure password',
                                  ),

                                  SizedBox(height: 30),


                                  _buildSectionHeader('Contact Details'),
                                  SizedBox(height: 25),


                                  _buildTextField(
                                    controller: mobileController,
                                    label: 'Mobile Number',
                                    icon: Icons.phone_android_outlined,
                                    hint: '10-digit mobile number',
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value!.isEmpty) return 'Please enter mobile number';
                                      if (value.length != 10) return 'Enter valid 10-digit number';
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 20),


                                  _buildTextField(
                                    controller: wardnoController,
                                    label: 'Ward Number',
                                    icon: Icons.numbers_outlined,
                                    hint: 'Enter ward number',
                                    keyboardType: TextInputType.number,
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
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: districtController,
                                          label: 'District',
                                          icon: Icons.location_city_outlined,
                                          hint: 'District name',
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
                                          Icon(Icons.person_add_alt_1_rounded, size: 22),
                                          SizedBox(width: 12),
                                          Text(
                                            'JOIN AS CITIZEN',
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
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF5D6D7E),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => UserLogin()),
                                          ),
                                          child: Text(
                                            'Login Here',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1A5F7A),
                                              decoration: TextDecoration.underline,
                                              decorationThickness: 1.5,
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

                        SizedBox(height: 30),


                        Container(
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Color(0xFF1A5F7A).withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    color: Color(0xFF1A5F7A),
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Citizen Benefits',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A5F7A),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildBenefitItem(Icons.track_changes_rounded, 'Real-time tender tracking'),
                              _buildBenefitItem(Icons.feedback_rounded, 'Submit feedback & complaints'),
                              _buildBenefitItem(Icons.visibility_rounded, 'Transparent progress monitoring'),
                              _buildBenefitItem(Icons.verified_user_rounded, 'Verified government data'),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),
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
        if (value!.isEmpty) return 'Please enter password';
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

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(0xFF1A5F7A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Color(0xFF1A5F7A),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter email';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value) ? null : 'Please enter a valid email address';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}