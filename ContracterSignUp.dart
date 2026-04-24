import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tender/contractor/ContracterLogin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ContracterSignUp(),
  ));
}

class ContracterSignUp extends StatefulWidget {
  @override
  _ContracterSignUpState createState() => _ContracterSignUpState();
}

class _ContracterSignUpState extends State<ContracterSignUp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController wardnoController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  bool isLoader = false;
  bool _obscurePassword = true;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoader = true);
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        User? user = userCredential.user;
        if (user != null) {
          await _database.child('Contractor').child(user.uid).set({
            'name': nameController.text,
            'email': emailController.text,
            'password': passwordController.text,
            'mobile': mobileController.text,
            'wardno': wardnoController.text,
            'location': locationController.text,
            'district': districtController.text,
            'ckey': user.uid,
            'registrationDate': DateTime.now().toIso8601String(),
            'status': 'pending_verification',
          });
          await sendVerificationEmail();


          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => SuccessDialog(
              onContinue: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ContracterLogin()),
                );
              },
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('FirebaseAuthException:', ''),
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      setState(() => isLoader = false);
    }
  }

  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/pattern.png'),
                  fit: BoxFit.cover,
                  opacity: 0.03,
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Contractor Registration',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A5F7A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),


                    SizedBox(height: 10),


                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Register to access government tender opportunities',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF5D6D7E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [


                              SizedBox(height: 25),


                              _buildSectionHeader('Personal Information'),
                              SizedBox(height: 15),

                              _buildTextField(
                                controller: nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                hint: 'Enter your full name',
                                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                              ),

                              SizedBox(height: 15),

                              _buildTextField(
                                controller: emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                hint: 'your.email@example.com',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) => value!.isEmpty ? 'Please enter your Email' : null,
                              ),

                              SizedBox(height: 15),

                              _buildPasswordField(
                                controller: passwordController,
                                label: 'Password',
                                hint: 'Create a strong password',
                              ),

                              SizedBox(height: 25),


                              _buildSectionHeader('Contact Details'),
                              SizedBox(height: 15),

                              _buildTextField(
                                controller: mobileController,
                                label: 'Mobile Number',
                                icon: Icons.phone_android_outlined,
                                hint: 'Enter 10-digit mobile number',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value!.isEmpty) return 'Please enter mobile number';
                                  if (value.length != 10) return 'Enter valid 10-digit number';
                                  return null;
                                },
                              ),

                              SizedBox(height: 15),

                              _buildTextField(
                                controller: wardnoController,
                                label: 'Ward Number',
                                icon: Icons.numbers_outlined,
                                hint: 'Enter ward number',
                                keyboardType: TextInputType.number,
                              ),

                              SizedBox(height: 15),

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
                                  SizedBox(width: 15),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: districtController,
                                      label: 'District',
                                      icon: Icons.location_city_outlined,
                                      hint: 'District',
                                    ),
                                  ),
                                ],
                              ),



                              SizedBox(height: 35),


                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoader ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A5F7A),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    shadowColor: const Color(0xFF1A5F7A).withOpacity(0.3),
                                  ),
                                  child: isLoader
                                      ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                      : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_alt_1_rounded, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'REGISTER AS CONTRACTOR',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),


                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ContracterLogin()),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1A5F7A),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF5D6D7E),
                                      ),
                                      children: [
                                        TextSpan(text: 'Already have an account? '),
                                        TextSpan(
                                          text: 'Login Here',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1A5F7A),
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


                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF1A5F7A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
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
        fontSize: 15,
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
        fontSize: 15,
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
            color: Colors.grey.shade500,
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
      ),
    );
  }

}


class SuccessDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const SuccessDialog({Key? key, required this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2D936C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 50,
                color: const Color(0xFF2D936C),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Registration Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A5F7A),
              ),
            ),
            SizedBox(height: 15),
            Text(
              'A verification email has been sent to your inbox. Please verify your email to complete the registration process.',
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
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5F7A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'CONTINUE TO LOGIN',
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
    );
  }
}