import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';


import '../department/DepartmentHome.dart';



class AuthServiceDepartment {
  Future<void> departmentLogin(Map<String, String> data, BuildContext context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email']!,
        password: data['password']!,
      );

      User? user = credential.user;

      if (user == null) {
        throw Exception("Department not found");
      }


      if (!user.emailVerified) {
        await user.sendEmailVerification();
        throw Exception("Email not verified. Verification email sent.");
      }

      DatabaseReference _database = FirebaseDatabase.instance.reference();
      String userId = user.uid;


      DatabaseReference databaseReference = _database.child('Department').child(userId);
      DatabaseEvent event = await databaseReference.once();

      if (event.snapshot.value == null) {
        throw Exception("No account found for this department");
      }

      var userData = event.snapshot.value;
      if (userData is! Map) {
        throw Exception("Invalid department data format");
      }


      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DepartmentHome()),
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
