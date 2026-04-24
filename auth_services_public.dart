import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../User/UserHome.dart';




class AuthServicePublic {
  Future<void> userLogin(Map<String, String> data, BuildContext context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email']!,
        password: data['password']!,
      );

      User? user = credential.user;

      if (user == null) {
        throw Exception("User not found");
      }


      if (!user.emailVerified) {
        await user.sendEmailVerification();
        throw Exception("Email not verified. Verification email sent.");
      }

      DatabaseReference _database = FirebaseDatabase.instance.reference();
      String userId = user.uid;


      DatabaseReference databaseReference = _database.child('Users').child(userId);
      DatabaseEvent event = await databaseReference.once();

      if (event.snapshot.value == null) {
        throw Exception("No account found for this user");
      }

      var userData = event.snapshot.value;
      if (userData is! Map) {
        throw Exception("Invalid user data format");
      }


      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => UserHome()),
            (Route<dynamic> route) => false,
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );


      throw e;
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
