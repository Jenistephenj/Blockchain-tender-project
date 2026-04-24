import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../government/GovernmentHome.dart';







class AuthServiceGovernment {
  Future<void> governmentlogin(Map<String, String> data, BuildContext context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email']!,
        password: data['password']!,
      );

      User? user = FirebaseAuth.instance.currentUser;

      user = FirebaseAuth.instance.currentUser;
      if (user!.emailVerified) {
        DatabaseReference _database = FirebaseDatabase.instance.reference();
        String? userId = user.uid;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successfully')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>  GovernmentHome(




            ),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Login Error"),
            content: Text(e.toString()),
          );
        },
      );
    }
  }

  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      print("Verification email sent to ${user.email}");
    }
  }
}
