// import 'package:daimond_host_provider/constants/colors.dart';
// import 'package:daimond_host_provider/localization/language_constants.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import '../utils/failure_dialogue.dart';
// import '../screens/main_screen.dart';
//
// class OTPLoginScreen extends StatefulWidget {
//   final String verificationId;
//   final String phoneNumber;
//   const OTPLoginScreen({
//     Key? key,
//     required this.verificationId,
//     required this.phoneNumber,
//   }) : super(key: key);
//
//   @override
//   _OTPLoginScreenState createState() => _OTPLoginScreenState();
// }
//
// class _OTPLoginScreenState extends State<OTPLoginScreen> {
//   final TextEditingController _otpController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//
//   bool _isLoading = false;
//
//   void _verifyOTP() async {
//     String smsCode = _otpController.text.trim();
//
//     if (smsCode.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (context) => FailureDialog(
//           text: 'Invalid OTP',
//           text1: 'Please enter the OTP code.',
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       final credential = PhoneAuthProvider.credential(
//         verificationId: widget.verificationId,
//         smsCode: smsCode,
//       );
//
//       UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       User? user = userCredential.user;
//
//       if (user != null) {
//         String uid = user.uid;
//         String? token = await FirebaseMessaging.instance.getToken();
//         if (token != null) {
//           await _databaseRef.child("App/User/$uid").update({"Token": token});
//         }
//
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (_) => const MainScreen()),
//           (Route<dynamic> route) => false,
//         );
//       } else {
//         showDialog(
//           context: context,
//           builder: (context) => FailureDialog(
//             text: 'OTP Verification Failed',
//             text1: 'Unable to retrieve user information. Please try again.',
//           ),
//         );
//       }
//     } on FirebaseAuthException {
//       showDialog(
//         context: context,
//         builder: (context) => const FailureDialog(
//           text: 'OTP Verification Failed',
//           text1: 'You have entered an incorrect OTP code. Please try again.',
//         ),
//       );
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (context) => FailureDialog(
//           text: 'OTP Verification Failed',
//           text1: 'An unexpected error occurred. Please try again.',
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   void dispose() {
//     _otpController.dispose();
//     super.dispose();
//   }
//
//   Widget _buildOTPField() {
//     return TextField(
//       controller: _otpController,
//       decoration: InputDecoration(
//         prefixIcon: const Icon(Icons.lock_outline),
//         labelText: getTranslated(context, 'OTP Code'),
//         hintText: getTranslated(context, 'Enter 6-digit OTP'),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//         counterText: '',
//       ),
//       keyboardType: TextInputType.number,
//       maxLength: 6,
//     );
//   }
//
//   Widget _buildVerifyButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 50,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : _verifyOTP,
//         style: ElevatedButton.styleFrom(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
//           backgroundColor: kPurpleColor,
//         ),
//         child: _isLoading
//             ? const CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               )
//             : Text(
//                 getTranslated(context, 'Verify OTP'),
//                 style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white),
//               ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Column(
//       children: [
//         Icon(
//           Icons.verified_user,
//           size: 100,
//           color: Theme.of(context).brightness == Brightness.dark
//               ? Colors.white
//               : kPurpleColor,
//         ),
//         const SizedBox(height: 20),
//         Text(
//           getTranslated(context, "OTP Verification"),
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Theme.of(context).brightness == Brightness.dark
//                 ? Colors.white
//                 : kPurpleColor,
//           ),
//         ),
//         const SizedBox(height: 10),
//         Text(
//           getTranslated(context, "Enter the OTP sent to"),
//           style: TextStyle(
//             fontSize: 16,
//             color: Theme.of(context).brightness == Brightness.dark
//                 ? Colors.white
//                 : Colors.grey[700],
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           widget.phoneNumber,
//           style: TextStyle(
//             fontSize: 18,
//             color: Theme.of(context).brightness == Brightness.dark
//                 ? Colors.white
//                 : kPurpleColor,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         iconTheme: IconThemeData(color: kPurpleColor),
//         title: Text(
//           getTranslated(context, "OTP Verification"),
//           style: TextStyle(color: kPurpleColor),
//         ),
//       ),
//       body: GestureDetector(
//         onTap: () => FocusScope.of(context).unfocus(),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildHeader(),
//               const SizedBox(height: 40),
//               _buildOTPField(),
//               const SizedBox(height: 30),
//               _buildVerifyButton(),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/failure_dialogue.dart';
import '../screens/main_screen.dart';

class OTPLoginScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  const OTPLoginScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _OTPLoginScreenState createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  bool _isLoading = false;

  Future<void> _saveDeviceToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _db.child('App/User/$uid/Tokens/$token').set({
        'createdAt': ServerValue.timestamp,
        'active': true,
      });
    } catch (e) {
      debugPrint('[OTPLogin] save token error: $e');
    }
  }

  void _verifyOTP() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => FailureDialog(
          text: 'Invalid OTP',
          text1: 'Please enter the OTP code.',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        await _saveDeviceToken(user.uid);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (r) => false,
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (_) => FailureDialog(
            text: 'OTP Verification Failed',
            text1: 'Unable to retrieve user information. Please try again.',
          ),
        );
      }
    } on FirebaseAuthException {
      showDialog(
        context: context,
        builder: (_) => const FailureDialog(
          text: 'OTP Verification Failed',
          text1: 'You have entered an incorrect OTP code. Please try again.',
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => FailureDialog(
          text: 'OTP Verification Failed',
          text1: 'An unexpected error occurred. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Widget _buildOTPField() {
    return TextField(
      controller: _otpController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline),
        labelText: getTranslated(context, 'OTP Code'),
        hintText: getTranslated(context, 'Enter 6-digit OTP'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        counterText: '',
      ),
      keyboardType: TextInputType.number,
      maxLength: 6,
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOTP,
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          backgroundColor: kPurpleColor,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : Text(
                getTranslated(context, 'Verify OTP'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.verified_user,
          size: 100,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : kPurpleColor,
        ),
        const SizedBox(height: 20),
        Text(
          getTranslated(context, "OTP Verification"),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : kPurpleColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          getTranslated(context, "Enter the OTP sent to"),
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.phoneNumber,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : kPurpleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kPurpleColor),
        title: Text(getTranslated(context, "OTP Verification"),
            style: const TextStyle(color: kPurpleColor)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildOTPField(),
              const SizedBox(height: 30),
              _buildVerifyButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
