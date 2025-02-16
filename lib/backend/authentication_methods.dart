// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../screens/main_screen.dart';
// import '../screens/fill_info_screen.dart';
// import '../screens/otp_screen.dart';
//
// class AuthenticationMethods {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _db = FirebaseDatabase.instance.ref();
//
//   Future<void> signUpWithEmailPhone({
//     required String email,
//     required String password,
//     required String phone,
//     required bool acceptedTerms,
//     required String agentCode, // New parameter for Agent Code
//     required BuildContext context,
//   }) async {
//     try {
//       if (!validatePassword(password)) {
//         throw Exception(
//             "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter");
//       }
//       await sendOTP(phone, context, email, password, acceptedTerms,
//           agentCode); // Pass Agent Code
//     } catch (e) {
//       throw Exception('Sign up failed: ${e.toString()}');
//     }
//   }
//
//   Future<void> authenticateWithPhoneAndEmail({
//     required String email,
//     required String password,
//     required String phone,
//     required String verificationId,
//     required String smsCode,
//     required bool acceptedTerms,
//     required String agentCode, // New parameter for Agent Code
//     required BuildContext context,
//   }) async {
//     try {
//       PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: smsCode,
//       );
//
//       UserCredential phoneUserCredential =
//           await _auth.signInWithCredential(phoneCredential);
//       AuthCredential emailCredential = EmailAuthProvider.credential(
//         email: email,
//         password: password,
//       );
//
//       await phoneUserCredential.user!.linkWithCredential(emailCredential);
//       final userId = phoneUserCredential.user?.uid;
//
//       if (userId == null) {
//         throw Exception("User ID is null after linking credentials.");
//       }
//
//       await _saveUserData(
//         email: email,
//         password: password,
//         phone: phone,
//         userId: userId,
//         acceptedTerms: acceptedTerms,
//         agentCode: agentCode,
//       );
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const FillInfoScreen()),
//       );
//     } catch (e) {
//       throw Exception('Phone and Email authentication failed: ${e.toString()}');
//     }
//   }
//
//   Future<void> sendOTP(
//     String phoneNumber,
//     BuildContext context,
//     String email,
//     String password,
//     bool acceptedTerms,
//     String agentCode, // New parameter for Agent Code
//   ) async {
//     await _auth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await authenticateWithPhoneAndEmail(
//           email: email,
//           password: password,
//           phone: phoneNumber,
//           verificationId: '',
//           smsCode: '',
//           acceptedTerms: acceptedTerms,
//           agentCode: agentCode, // Pass Agent Code
//           context: context,
//         );
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         throw Exception('Phone verification failed: ${e.message}');
//       },
//       codeSent: (String verificationId, int? resendToken) async {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => OTPScreen(
//               verificationId: verificationId,
//               phoneNumber: phoneNumber,
//               email: email,
//               password: password,
//               acceptedTerms: acceptedTerms,
//               agentCode: agentCode, // Pass Agent Code
//             ),
//           ),
//         );
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         print("Timeout");
//       },
//       timeout: const Duration(seconds: 120),
//     );
//   }
//
//   Future<void> _saveUserData({
//     required String email,
//     required String password,
//     required String phone,
//     required String userId,
//     required bool acceptedTerms,
//     required String agentCode, // New parameter for Agent Code
//   }) async {
//     try {
//       String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
//       String? token = await FirebaseMessaging.instance.getToken();
//       await _db.child('App/User/$userId').set({
//         'Email': email,
//         'Password': password,
//         'PhoneNumber': phone,
//         'AcceptedTermsAndConditions': acceptedTerms,
//         'AgentCode':
//             agentCode.isEmpty ? null : agentCode, // Save Agent Code if provided
//         'TypeUser': '2',
//         'DateOfRegistration': registrationDate,
//         'TypeAccount': '1',
//         'Token': token,
//         'IsVerified': true,
//       });
//     } catch (error) {
//       print("Error saving data to Firebase: $error");
//     }
//   }
//
//   bool validatePassword(String password) {
//     final RegExp passwordRegExp =
//         RegExp(r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$');
//     return passwordRegExp.hasMatch(password);
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/fill_info_screen.dart';
import '../screens/otp_screen.dart';
import '../utils/failure_dialogue.dart';

class AuthenticationMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> signUpWithEmailPhone({
    required String email,
    required String password,
    required String phone,
    required bool acceptedTerms,
    required String agentCode,
    required BuildContext context,
  }) async {
    try {
      if (!validatePassword(password)) {
        throw Exception(
          "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter",
        );
      }

      // Check if email or phone already exists in Firebase
      bool emailExists = await _checkIfEmailExists(email);
      bool phoneExists = await _checkIfPhoneExists(phone);

      if (emailExists || phoneExists) {
        // Show failure dialog if either email or phone exists
        showDialog(
          context: context,
          builder: (_) => const FailureDialog(
            text: 'Account already exists',
            // text1: emailExists
            //     ? 'This email is already registered.'
            //     : 'This phone number is already registered.',
            text1: 'This email or phone number is already registered',
          ),
        );
        return; // Stop further actions
      }

      // If validation passes, send OTP
      await sendOTP(phone, context, email, password, acceptedTerms, agentCode);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<void> authenticateWithPhoneAndEmail({
    required String email,
    required String password,
    required String phone,
    required String verificationId,
    required String smsCode,
    required bool acceptedTerms,
    required String agentCode,
    required BuildContext context,
  }) async {
    try {
      PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential phoneUserCredential =
          await _auth.signInWithCredential(phoneCredential);
      AuthCredential emailCredential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await phoneUserCredential.user!.linkWithCredential(emailCredential);
      final userId = phoneUserCredential.user?.uid;

      if (userId == null) {
        throw Exception("User ID is null after linking credentials.");
      }

      await _saveUserData(
        email: email,
        password: password,
        phone: phone,
        userId: userId,
        acceptedTerms: acceptedTerms,
        agentCode: agentCode,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FillInfoScreen()),
      );
    } catch (e) {
      throw Exception('Phone and Email authentication failed: ${e.toString()}');
    }
  }

  Future<void> sendOTP(
    String phoneNumber,
    BuildContext context,
    String email,
    String password,
    bool acceptedTerms,
    String agentCode,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await authenticateWithPhoneAndEmail(
          email: email,
          password: password,
          phone: phoneNumber,
          verificationId: '',
          smsCode: '',
          acceptedTerms: acceptedTerms,
          agentCode: agentCode,
          context: context,
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
              email: email,
              password: password,
              acceptedTerms: acceptedTerms,
              agentCode: agentCode,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print("Timeout");
      },
      timeout: const Duration(seconds: 120),
    );
  }

  Future<void> _saveUserData({
    required String email,
    required String password,
    required String phone,
    required String userId,
    required bool acceptedTerms,
    required String agentCode,
  }) async {
    try {
      String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      String? token = await FirebaseMessaging.instance.getToken();
      await _db.child('App/User/$userId').set({
        'Email': email,
        'Password': password,
        'PhoneNumber': phone,
        'AcceptedTermsAndConditions': acceptedTerms,
        'AgentCode': agentCode.isEmpty ? null : agentCode,
        'TypeUser': '2',
        'DateOfRegistration': registrationDate,
        'TypeAccount': '1',
        'Token': token,
        'IsVerified': true,
      });
    } catch (error) {
      print("Error saving data to Firebase: $error");
    }
  }

  bool validatePassword(String password) {
    final RegExp passwordRegExp =
        RegExp(r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$');
    return passwordRegExp.hasMatch(password);
  }

  Future<bool> _checkIfEmailExists(String email) async {
    try {
      final snapshot = await _db
          .child('App/User')
          .orderByChild('Email')
          .equalTo(email)
          .once();

      return snapshot.snapshot.exists;
    } catch (e) {
      print("Error checking email existence: $e");
      return false;
    }
  }

  Future<bool> _checkIfPhoneExists(String phone) async {
    try {
      final snapshot = await _db
          .child('App/User')
          .orderByChild('PhoneNumber')
          .equalTo(phone)
          .once();

      return snapshot.snapshot.exists;
    } catch (e) {
      print("Error checking phone existence: $e");
      return false;
    }
  }
}
