import 'package:flutter/material.dart';
import 'package:tender/contractor/ContracterSignUp.dart';

import 'package:tender/utills/appvalidator.dart';
import '../services/auth_services_contractor.dart';
import 'ContracterHome.dart';

class ContracterLogin extends StatefulWidget {
  ContracterLogin({Key? key}) : super(key: key);

  @override
  _ContracterLoginState createState() => _ContracterLoginState();
}

class _ContracterLoginState extends State<ContracterLogin> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  final AuthServiceContractor authService = AuthServiceContractor();
  final AppValidator appValidator = AppValidator();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    var data = {
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
    };

    try {
      await authService.contractorLogin(data, context);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ContracterHome(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }

    setState(() => isLoading = false);
  }

  void _showErrorDialog(String message) {
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Login Failed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 15),
              Text(
                message.replaceAll('FirebaseAuthException:', ''),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF5D6D7E),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5F7A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'TRY AGAIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [

          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1A5F7A).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF2D936C).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SingleChildScrollView(
            child: SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height,
                padding: EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [


                        SizedBox(height: 20),

                        Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1A5F7A),
                                          Color(0xFF2D936C),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF1A5F7A).withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.business_center_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 25),
                                  Text(
                                    'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A5F7A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Login to access tender opportunities',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF5D6D7E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),


                        SizedBox(height: 40),


                        Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Container(
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
                              padding: EdgeInsets.all(30),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [

                                    _buildTextField(
                                      controller: emailController,
                                      label: 'Email Address',
                                      icon: Icons.email_outlined,
                                      hint: 'contractor@example.com',
                                      keyboardType: TextInputType.emailAddress,
                                      validator: appValidator.validateEmail,
                                    ),

                                    SizedBox(height: 25),


                                    _buildPasswordField(
                                      controller: passwordController,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      validator: appValidator.validatepassword,
                                    ),

                                    SizedBox(height: 10),



                                    SizedBox(height: 35),


                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1A5F7A),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 18),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          elevation: 2,
                                          shadowColor: const Color(0xFF1A5F7A).withOpacity(0.3),
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
                                            Text(
                                              'LOGIN TO DASHBOARD',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Icon(Icons.arrow_forward_rounded, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 30),


                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 15),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              color: const Color(0xFF7F8C8D),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 25),


                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'New contractor? ',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: const Color(0xFF5D6D7E),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => ContracterSignUp()),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(0xFF1A5F7A),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.underline,
                                              decorationThickness: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        Spacer(),



                        SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
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
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        labelStyle: TextStyle(
          color: const Color(0xFF5D6D7E),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.only(right: 15, left: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5F7A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(12),
          child: Icon(
            icon,
            color: const Color(0xFF1A5F7A),
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
          borderSide: BorderSide(color: const Color(0xFF1A5F7A), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        errorStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePassword,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        labelStyle: TextStyle(
          color: const Color(0xFF5D6D7E),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.only(right: 15, left: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5F7A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(12),
          child: Icon(
            Icons.lock_outline_rounded,
            color: const Color(0xFF1A5F7A),
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
            color: const Color(0xFF5D6D7E),
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
          borderSide: BorderSide(color: const Color(0xFF1A5F7A), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        errorStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}