import 'package:animate_do/animate_do.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../main.dart';

import '../services/auth_services_government.dart';
import '../utills/appvalidator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    home: GovernmentLogin(),
    debugShowCheckedModeBanner: false,
  ));
}

class GovernmentLogin extends StatefulWidget {
  GovernmentLogin({Key? key}) : super(key: key);

  @override
  _GovernmentLoginState createState() => _GovernmentLoginState();
}

class _GovernmentLoginState extends State<GovernmentLogin> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  var authService = AuthServiceGovernment();
  var appValidator = AppValidator();

  Future<void> _submitForm() async {
    setState(() => isLoading = true);
    var data = {
      "email": emailController.text,
      "password": passwordController.text,
    };
    await authService.governmentlogin(data, context);
    setState(() => isLoading = false);
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp()));
    return false;
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      prefixIcon: Icon(icon, color: Colors.white),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      hintStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/govlog.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                  ),
                ),
              ),
            ),


            Center(
              child: FadeInUp(
                duration: Duration(milliseconds: 600),
                child: Container(
                  width: 400,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: _formkey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10),
                        FadeInDown(
                          child: Icon(Icons.gavel, color: Colors.white, size: 80),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Admin Login',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        FadeInLeft(
                          child: TextFormField(
                            controller: emailController,
                            style: TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration("Email", Icons.email),
                            validator: appValidator.validateEmail,
                          ),
                        ),
                        SizedBox(height: 10),
                        FadeInRight(
                          child: TextFormField(
                            controller: passwordController,
                            style: TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            obscureText: true,
                            decoration: _buildInputDecoration("Password", Icons.lock),
                            validator: appValidator.validatepassword,
                          ),
                        ),
                        SizedBox(height: 20),
                        FadeInUp(
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submitForm,
                              child: isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
