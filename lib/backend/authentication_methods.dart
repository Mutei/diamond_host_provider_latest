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

  // Helper to check if a phone number is blocked.
  Future<bool> _isPhoneBlocked(String phoneNumber) async {
    try {
      final snapshot = await _db.child('BlockedNumbers/$phoneNumber').once();
      return snapshot.snapshot.exists && snapshot.snapshot.value == true;
    } catch (e) {
      print("Error checking phone block status: $e");
      return false;
    }
  }

  Future<void> signUpWithEmailPhone({
    required String email,
    required String password,
    required String phone,
    required bool acceptedTerms,
    required String agentCode,
    required BuildContext context,
  }) async {
    // Normalize email to lower-case for consistent checking and storage
    final normalizedEmail = email.trim().toLowerCase();

    // 1. Password rules
    if (!validatePassword(password)) {
      throw Exception(
        "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter",
      );
    }

    // 2. Check if email already exists (case-insensitive)
    bool emailExists = await _checkIfEmailExists(normalizedEmail);
    bool phoneExists = await _checkIfPhoneExists(phone);
    if (emailExists || phoneExists) {
      await showDialog(
        context: context,
        builder: (_) => const FailureDialog(
          text: 'Account already exists',
          text1: "This email or phone number is already registered",
        ),
      );
      return;
    }

    // 3. Check if phone is blocked
    bool isBlocked = await _isPhoneBlocked(phone);
    if (isBlocked) {
      await showDialog(
        context: context,
        builder: (_) => const FailureDialog(
          text:
              "This phone number is temporarily blocked. Please try again later.",
          text1: "",
        ),
      );
      return;
    }

    // 4. All validation passed—now send the OTP
    await sendOTP(
        phone, context, normalizedEmail, password, acceptedTerms, agentCode);
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
        email: email.trim().toLowerCase(),
        password: password,
      );

      await phoneUserCredential.user!.linkWithCredential(emailCredential);
      final userId = phoneUserCredential.user?.uid;

      if (userId == null) {
        throw Exception("User ID is null after linking credentials.");
      }

      await _saveUserData(
        email: email.trim().toLowerCase(),
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
        try {
          UserCredential userCredential =
              await _auth.signInWithCredential(credential);

          AuthCredential emailCredential = EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          await userCredential.user!.linkWithCredential(emailCredential);

          final userId = userCredential.user?.uid;
          if (userId != null) {
            await _saveUserData(
              email: email,
              password: password,
              phone: phoneNumber,
              userId: userId,
              acceptedTerms: acceptedTerms,
              agentCode: agentCode,
            );
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const FillInfoScreen()),
            (Route<dynamic> route) => false,
          );
        } catch (e) {
          print('Auto verification linking failed: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'too-many-requests') {
          showDialog(
            context: context,
            builder: (_) => const FailureDialog(
              text:
                  "Too many requests from this phone number. Please try again later.",
              text1: "",
            ),
          );
        } else {
          throw Exception('Phone verification failed: ${e.message}');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
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
        'Email': email, // now always stored lower-case
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

  /// Case‑insensitive email existence check by scanning all users.
  Future<bool> _checkIfEmailExists(String normalizedEmail) async {
    try {
      final snapshot = await _db.child('App/User').once();
      if (!snapshot.snapshot.exists) return false;

      final allUsers = snapshot.snapshot.value as Map<dynamic, dynamic>;
      for (final userData in allUsers.values) {
        final storedEmail = (userData['Email'] as String?)?.toLowerCase();
        if (storedEmail == normalizedEmail) {
          return true;
        }
      }
      return false;
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

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../screens/fill_info_screen.dart';
// import '../screens/otp_screen.dart';
// import '../utils/failure_dialogue.dart';
//
// class AuthenticationMethods {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _db = FirebaseDatabase.instance.ref();
//
//   // Helper to check if a phone number is blocked.
//   Future<bool> _isPhoneBlocked(String phoneNumber) async {
//     try {
//       final snapshot = await _db.child('BlockedNumbers/$phoneNumber').once();
//       return snapshot.snapshot.exists && snapshot.snapshot.value == true;
//     } catch (e) {
//       print("Error checking phone block status: $e");
//       return false;
//     }
//   }
//
//   Future<void> signUpWithEmailPhone({
//     required String email,
//     required String password,
//     required String phone,
//     required bool acceptedTerms,
//     required String agentCode,
//     required BuildContext context,
//   }) async {
//     try {
//       if (!validatePassword(password)) {
//         throw Exception(
//           "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter",
//         );
//       }
//
//       bool emailExists = await _checkIfEmailExists(email);
//       bool phoneExists = await _checkIfPhoneExists(phone);
//
//       if (emailExists || phoneExists) {
//         showDialog(
//           context: context,
//           builder: (_) => const FailureDialog(
//             text: 'Account already exists',
//             text1: 'This email or phone number is already registered',
//           ),
//         );
//         return;
//       }
//
//       bool isBlocked = await _isPhoneBlocked(phone);
//       if (isBlocked) {
//         showDialog(
//           context: context,
//           builder: (_) => const FailureDialog(
//             text:
//                 "This phone number is temporarily blocked. Please try again later.",
//             text1: "",
//           ),
//         );
//         return;
//       }
//
//       await sendOTP(phone, context, email, password, acceptedTerms, agentCode);
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
//     required String agentCode,
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
//     String agentCode,
//   ) async {
//     await _auth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         try {
//           UserCredential userCredential =
//               await _auth.signInWithCredential(credential);
//
//           AuthCredential emailCredential = EmailAuthProvider.credential(
//             email: email,
//             password: password,
//           );
//           await userCredential.user!.linkWithCredential(emailCredential);
//
//           final userId = userCredential.user?.uid;
//           if (userId != null) {
//             String? token = await FirebaseMessaging.instance.getToken();
//             // Update tokens map instead of a single token field.
//             if (token != null) {
//               await _db.child('App/User/$userId/Token').update({token: true});
//             }
//             await _saveUserData(
//               email: email,
//               password: password,
//               phone: phoneNumber,
//               userId: userId,
//               acceptedTerms: acceptedTerms,
//               agentCode: agentCode,
//             );
//           }
//
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (context) => const FillInfoScreen()),
//             (Route<dynamic> route) => false,
//           );
//         } catch (e) {
//           print('Auto verification linking failed: $e');
//         }
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         if (e.code == 'too-many-requests') {
//           showDialog(
//             context: context,
//             builder: (_) => const FailureDialog(
//               text:
//                   "Too many requests from this phone number. Please try again later.",
//               text1: "",
//             ),
//           );
//         } else {
//           throw Exception('Phone verification failed: ${e.message}');
//         }
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
//               agentCode: agentCode,
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
//     required String agentCode,
//   }) async {
//     try {
//       String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
//       String? token = await FirebaseMessaging.instance.getToken();
//       await _db.child('App/User/$userId').set({
//         'Email': email,
//         'Password': password,
//         'PhoneNumber': phone,
//         'AcceptedTermsAndConditions': acceptedTerms,
//         'AgentCode': agentCode.isEmpty ? null : agentCode,
//         'TypeUser': '2',
//         'DateOfRegistration': registrationDate,
//         'TypeAccount': '1',
//         // Store tokens in a map. If a token exists, add it.
//         'Token': token != null ? {token: true} : {},
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
//
//   Future<bool> _checkIfEmailExists(String email) async {
//     try {
//       final snapshot = await _db
//           .child('App/User')
//           .orderByChild('Email')
//           .equalTo(email)
//           .once();
//
//       return snapshot.snapshot.exists;
//     } catch (e) {
//       print("Error checking email existence: $e");
//       return false;
//     }
//   }
//
//   Future<bool> _checkIfPhoneExists(String phone) async {
//     try {
//       final snapshot = await _db
//           .child('App/User')
//           .orderByChild('PhoneNumber')
//           .equalTo(phone)
//           .once();
//
//       return snapshot.snapshot.exists;
//     } catch (e) {
//       print("Error checking phone existence: $e");
//       return false;
//     }
//   }
// }
