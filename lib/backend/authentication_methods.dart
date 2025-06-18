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
//     // Normalize email to lower-case for consistent checking and storage
//     final normalizedEmail = email.trim().toLowerCase();
//
//     // 1. Password rules
//     if (!validatePassword(password)) {
//       throw Exception(
//         "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter",
//       );
//     }
//
//     // 2. Check if email already exists (case-insensitive)
//     bool emailExists = await _checkIfEmailExists(normalizedEmail);
//     bool phoneExists = await _checkIfPhoneExists(phone);
//     if (emailExists || phoneExists) {
//       await showDialog(
//         context: context,
//         builder: (_) => const FailureDialog(
//           text: 'Account already exists',
//           text1: "This email or phone number is already registered",
//         ),
//       );
//       return;
//     }
//
//     // 3. Check if phone is blocked
//     bool isBlocked = await _isPhoneBlocked(phone);
//     if (isBlocked) {
//       await showDialog(
//         context: context,
//         builder: (_) => const FailureDialog(
//           text:
//               "This phone number is temporarily blocked. Please try again later.",
//           text1: "",
//         ),
//       );
//       return;
//     }
//
//     // 4. All validation passed—now send the OTP
//     await sendOTP(
//         phone, context, normalizedEmail, password, acceptedTerms, agentCode);
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
//         email: email.trim().toLowerCase(),
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
//         email: email.trim().toLowerCase(),
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
//       codeSent: (String verificationId, int? resendToken) {
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
//         'Email': email, // now always stored lower-case
//         'Password': password,
//         'PhoneNumber': phone,
//         'AcceptedTermsAndConditions': acceptedTerms,
//         'AgentCode': agentCode.isEmpty ? null : agentCode,
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
//
//   /// Case‑insensitive email existence check by scanning all users.
//   Future<bool> _checkIfEmailExists(String normalizedEmail) async {
//     try {
//       final snapshot = await _db.child('App/User').once();
//       if (!snapshot.snapshot.exists) return false;
//
//       final allUsers = snapshot.snapshot.value as Map<dynamic, dynamic>;
//       for (final userData in allUsers.values) {
//         final storedEmail = (userData['Email'] as String?)?.toLowerCase();
//         if (storedEmail == normalizedEmail) {
//           return true;
//         }
//       }
//       return false;
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
    final normalizedEmail = email.trim().toLowerCase();

    if (!validatePassword(password)) {
      throw Exception(
        "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter",
      );
    }

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

    await _sendOTP(
      phone,
      context,
      normalizedEmail,
      password,
      acceptedTerms,
      agentCode,
    );
  }

  Future<void> _sendOTP(
    String phoneNumber,
    BuildContext context,
    String email,
    String password,
    bool acceptedTerms,
    String agentCode,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final emailCred = EmailAuthProvider.credential(
              email: email,
              password: password,
            );
            await userCredential.user!.linkWithCredential(emailCred);

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
              MaterialPageRoute(builder: (_) => const FillInfoScreen()),
              (route) => false,
            );
          } catch (e) {
            print('Auto verification linking failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) async {
          String dialogMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              dialogMessage =
                  'The phone number format is invalid. Use +9665XXXXXXXX.';
              break;
            case 'quota-exceeded':
              dialogMessage =
                  'SMS quota exceeded for this number. Please wait and try again later.';
              break;
            case 'too-many-requests':
              dialogMessage =
                  'Too many attempts. Please wait a while before retrying.';
              break;
            default:
              dialogMessage =
                  'We couldn’t send an OTP to this number. It may be blocked by your carrier or by DND/Do-Not-Disturb settings. Please disable DND or use a different mobile number.';
          }
          await showDialog(
            context: context,
            builder: (_) => FailureDialog(
              text: 'Phone verification failed',
              text1: dialogMessage,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPScreen(
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
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => FailureDialog(
          text: 'Sign-up Error',
          text1: e.toString(),
        ),
      );
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
      final phoneCred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCred = await _auth.signInWithCredential(phoneCred);
      final emailCred = EmailAuthProvider.credential(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await userCred.user!.linkWithCredential(emailCred);

      final userId = userCred.user?.uid;
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
        MaterialPageRoute(builder: (_) => const FillInfoScreen()),
      );
    } catch (e) {
      throw Exception('Authentication failed: ${e.toString()}');
    }
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
      final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final token = await FirebaseMessaging.instance.getToken();
      await _db.child('App/User/$userId').set({
        'Email': email,
        'Password': password,
        'PhoneNumber': phone,
        'AcceptedTermsAndConditions': acceptedTerms,
        'AgentCode': agentCode.isEmpty ? null : agentCode,
        'TypeUser': '2',
        'DateOfRegistration': date,
        'TypeAccount': '1',
        'Token': token,
        'IsVerified': true,
      });
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  bool validatePassword(String pw) {
    final re = RegExp(r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$');
    return re.hasMatch(pw);
  }

  Future<bool> _checkIfEmailExists(String normalizedEmail) async {
    try {
      final snap = await _db.child('App/User').once();
      if (!snap.snapshot.exists) return false;
      final users = Map<String, dynamic>.from(snap.snapshot.value as Map);
      return users.values.any(
          (u) => (u['Email'] as String?)?.toLowerCase() == normalizedEmail);
    } catch (e) {
      print("Error checking email: $e");
      return false;
    }
  }

  Future<bool> _checkIfPhoneExists(String phone) async {
    try {
      final snap = await _db
          .child('App/User')
          .orderByChild('PhoneNumber')
          .equalTo(phone)
          .once();
      return snap.snapshot.exists;
    } catch (e) {
      print("Error checking phone: $e");
      return false;
    }
  }
}
