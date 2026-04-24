import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../contractor/ContracterHome.dart';
import '../contractor/ContracterLogin.dart';






void main() {
  runApp(new MaterialApp(
    home: new AuthGateContractor(),
  ));
}


class AuthGateContractor extends StatelessWidget {
  const AuthGateContractor({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if(!snapshot.hasData) {
            return ContracterLogin();
          }
          return ContracterHome();
        }
    );
  }
}