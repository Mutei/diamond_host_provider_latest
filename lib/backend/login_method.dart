import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../screens/main_screen.dart';
import '../screens/otp_login_screen.dart';
import '../screens/otp_screen.dart';
import '../utils/global_methods.dart';

class LoginMethod {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // Method to handle email login
  void loginWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Show loading dialog
      showCustomLoadingDialog(context);

      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String? token = await FirebaseMessaging.instance.getToken();
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref("App/User/$uid");
      DatabaseReference typeUserRef =
          _databaseRef.child('App/User/$uid/TypeUser');
      DataSnapshot snapshot = await typeUserRef.get();

      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

      if (snapshot.value == '2') {
        if (token != null) {
          await userRef.update({"Token": token});
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        await _auth.signOut();
        showLoginErrorDialog(context, "You are not allowed to log in.");
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      showErrorDialog(context, e.message ?? "Login failed. Please try again.");
    }
  }

  void loginWithPhone({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    try {
      showCustomLoadingDialog(context);

      // Get users from Firebase and check TypeUser
      DatabaseReference userRef = _databaseRef.child('App/User');
      DataSnapshot usersSnapshot = await userRef.get();
      String? uid;

      for (var user in usersSnapshot.children) {
        final phone = user.child("PhoneNumber").value as String?;
        if (phone == phoneNumber) {
          uid = user.key;
          break;
        }
      }

      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading

      if (uid == null) {
        showErrorDialog(context, "User not found with this phone number.");
        return;
      }

      // Check TypeUser
      DatabaseReference typeUserRef = userRef.child('$uid/TypeUser');
      DataSnapshot snapshot = await typeUserRef.get();
      String? token = await FirebaseMessaging.instance.getToken();
      DatabaseReference userRefs =
          FirebaseDatabase.instance.ref("App/User/$uid");

      if (snapshot.value == '2') {
        // Proceed with OTP verification

        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-retrieval or instant verification
            if (token != null) {
              await userRefs.update({"Token": token});
            }
            await _auth.signInWithCredential(credential);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
            );
          },
          verificationFailed: (FirebaseAuthException e) {
            // Handle errors (e.g., invalid phone number)
            showErrorDialog(context, e.message ?? "Verification failed.");
          },
          codeSent: (String verificationId, int? resendToken) {
            // Navigate to OTP screen with verification ID for manual entry
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => OTPLoginScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ));
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Auto-retrieval timeout, pass the verification ID to the OTP screen
          },
        );
      } else {
        showLoginErrorDialog(context, "You are not allowed to log in.");
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      showErrorDialog(context, "An error occurred. Please try again.");
    }
  }

  Future<void> linkWithEmailAndPhone({
    required String email,
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
    required BuildContext context,
  }) async {
    try {
      // Authenticate the phone credential using OTP
      PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with the phone number first
      UserCredential phoneUserCredential =
          await _auth.signInWithCredential(phoneCredential);

      // Now, link email credential to the phone-authenticated user
      User? user = phoneUserCredential.user;
      AuthCredential emailCredential = EmailAuthProvider.credential(
        email: email,
        password: 'some_password', // You can also pass the password here
      );
      await user!.linkWithCredential(emailCredential);

      // After linking, navigate to the main screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      showErrorDialog(context, "Failed to link email with phone");
    }
  }

  // Helper function to check TypeUser
  void _checkTypeUser(String? uid, BuildContext context) async {
    if (uid == null) {
      showErrorDialog(context, "Unable to verify user ID.");
      return;
    }

    showCustomLoadingDialog(context);
    DatabaseReference typeUserRef =
        _databaseRef.child('App/User/$uid/TypeUser');
    DataSnapshot snapshot = await typeUserRef.get();

    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

    if (snapshot.value == '2') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      await _auth.signOut();
      showLoginErrorDialog(context, "You are not allowed to log in.");
    }
  }
}
