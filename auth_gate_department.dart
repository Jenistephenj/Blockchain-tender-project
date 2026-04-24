import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../department/DepartmentLogin.dart';
import '../department/DepartmentHome.dart';






void main() {
  runApp(new MaterialApp(
    home: new AuthGateDepartment(),
  ));
}


class AuthGateDepartment extends StatelessWidget {
  const AuthGateDepartment({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if(!snapshot.hasData) {
            return DepartmentLogin();
          }
          return DepartmentHome();
        }
    );
  }
}