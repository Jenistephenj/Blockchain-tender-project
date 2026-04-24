import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



import '../government/GovernmentLogin.dart';
import '../government/GovernmentHome.dart';








void main() {
  runApp(new MaterialApp(
    home: new AuthGateGovernment(),



  ));


}

class AuthGateGovernment extends StatelessWidget {
  const AuthGateGovernment({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if(!snapshot.hasData) {
            return GovernmentLogin();

          }
          return GovernmentHome();
        }

    );

  }
}








