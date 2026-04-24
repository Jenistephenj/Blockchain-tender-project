import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../User/UserHome.dart';

import '../user/UserLogin.dart';






void main() {
  runApp(new MaterialApp(
    home: new AuthGatePublic(),
  ));
}


class AuthGatePublic extends StatelessWidget {
  const AuthGatePublic({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if(!snapshot.hasData) {
            return UserLogin();
          }
          return UserHome();
        }
    );
  }
}