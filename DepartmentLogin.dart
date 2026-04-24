import 'package:flutter/material.dart';

import 'package:tender/utills/appvalidator.dart';

import '../services/auth_services_department.dart';
import 'DepartmentHome.dart';
import 'DepartmentSignUp.dart';

class DepartmentLogin extends StatefulWidget {
  DepartmentLogin({Key? key}) : super(key: key);

  @override
  _DepartmentLoginState createState() => _DepartmentLoginState();
}

class _DepartmentLoginState extends State<DepartmentLogin> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  final AuthServiceDepartment authService = AuthServiceDepartment();
  final AppValidator appValidator = AppValidator();

  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.4, curve: Curves.easeOutBack),
    );

    _formAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.3, 0.7, curve: Curves.easeInOut),
    );

    _buttonAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.6, 1.0, curve: Curves.easeInOut),
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
      await authService.departmentLogin(data, context);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => DepartmentHome(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }

    setState(() => isLoading = false);
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
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
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 25),
              Text(
                'Authentication Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 15),
              Text(
                error.replaceAll('FirebaseAuthException:', '').trim(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D6D7E),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A5F7A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
      backgroundColor: Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                SizedBox(height: 20),


                Center(
                  child: ScaleTransition(
                    scale: _headerAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF1A5F7A),
                                Color(0xFF2D936C),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
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
                          child: Icon(
                            Icons.account_balance_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),

                        SizedBox(height: 25),

                        Text(
                          'Welcome,\n Department',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A5F7A),
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),

                        SizedBox(height: 15),

                        Text(
                          'Access the secure tender management portal to oversee public procurement processes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF5D6D7E),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40),


                FadeTransition(
                  opacity: _formAnimation,
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
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [

                            _buildTextField(
                              controller: emailController,
                              label: 'Official Email Address',
                              icon: Icons.email_outlined,
                              hint: 'department@government.gov',
                              keyboardType: TextInputType.emailAddress,
                              validator: appValidator.validateEmail,
                            ),

                            SizedBox(height: 25),


                            _buildPasswordField(
                              controller: passwordController,
                              label: 'Secure Password',
                              hint: 'Enter your password',
                              validator: appValidator.validatepassword,
                            ),


                            SizedBox(height: 35),


                            ScaleTransition(
                              scale: _buttonAnimation,
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1A5F7A),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 18),
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
                                      Text(
                                        'ACCESS DEPARTMENT PORTAL',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ),
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
                                      color: Color(0xFF7F8C8D),
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
                                  'New Department? ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF5D6D7E),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => DepartmentSignUp()),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Color(0xFF1A5F7A),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Register Here',
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

                SizedBox(height: 40),


                FadeTransition(
                  opacity: _buttonAnimation,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSecurityFeature(Icons.verified_user_rounded, 'Verified'),
                            SizedBox(width: 30),
                            _buildSecurityFeature(Icons.lock_clock_rounded, 'Secure'),
                            SizedBox(width: 30),
                            _buildSecurityFeature(Icons.visibility_off_rounded, 'Private'),
                          ],
                        ),
                        SizedBox(height: 15),
                        Text(
                          'All department data is encrypted and accessible only to authorized personnel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
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
        errorStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFF1A5F7A).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: Color(0xFF1A5F7A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}