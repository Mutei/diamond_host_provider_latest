import 'dart:async';

import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:daimond_host_provider/backend/authentication_methods.dart';
import 'package:daimond_host_provider/screens/personal_info_screen.dart';
import '../backend/login_method.dart';
import '../constants/colors.dart';
import '../utils/failure_dialogue.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String email;
  final String password;
  final bool acceptedTerms;
  final String agentCode; // New parameter for Agent Code

  const OTPScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.acceptedTerms,
    required this.agentCode, // Add agent code here
  }) : super(key: key);

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();
  final AuthenticationMethods _loginMethod = AuthenticationMethods();
  bool _isLoading = false;
  int _resendCounter = 60; // Seconds before allowing resend
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCounter = 60;
    _canResend = false;
    const oneSec = Duration(seconds: 1);
    Timer.periodic(oneSec, (Timer timer) {
      if (_resendCounter == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _resendCounter--;
        });
      }
    });
  }

  String translateWithPlaceholder(
      BuildContext context, String key, Map<String, String> placeholders) {
    String translated = getTranslated(context, key);
    placeholders.forEach((placeholder, value) {
      translated = translated.replaceAll(placeholder, value);
    });
    return translated;
  }

  Future<void> _verifyOTP() async {
    bool isVerified = false;

    try {
      if (widget.verificationId.isEmpty || _otpController.text.trim().isEmpty) {
        throw Exception("Invalid OTP or Verification ID.");
      }

      await _loginMethod.authenticateWithPhoneAndEmail(
        email: widget.email,
        phone: widget.phoneNumber,
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
        context: context,
        password: widget.password,
        acceptedTerms: widget.acceptedTerms,
        agentCode: widget.agentCode, // Pass agent code
      );

      isVerified = true;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => FailureDialog(
          text: "OTP Verification Failed",
          text1: "You have entered an incorrect OTP code. Please try again.",
        ),
      );
    }

    if (isVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalInfoScreen(
            email: widget.email,
            phoneNumber: widget.phoneNumber,
            password: widget.password,
            typeUser: '2',
            typeAccount: '1',
          ),
        ),
      );
    }
  }

  Future<void> _resendOTP() async {
    // Implement your resend OTP logic here
    // For example, you might call Firebase's verifyPhoneNumber again
    // and handle the new verificationId
    // After resending, restart the timer
    _startResendTimer();

    // Show a snackbar or dialog to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getTranslated(
            context, 'OTP has been resent to your phone number.')),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.lock_outline,
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

  Widget _buildOTPField() {
    return TextField(
      controller: _otpController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.security),
        labelText: getTranslated(context, 'OTP Code'),
        hintText: getTranslated(context, 'Enter 6-digit OTP'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        counterText: '',
      ),
      keyboardType: TextInputType.number,
      maxLength: 6, // Assuming a 6-digit OTP
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                if (_otpController.text.isNotEmpty) {
                  setState(() {
                    _isLoading = true;
                  });
                  await _verifyOTP();
                } else {
                  // Show error if OTP is empty
                  showDialog(
                    context: context,
                    builder: (context) => FailureDialog(
                      text: 'Invalid OTP',
                      text1: 'Please enter the OTP code.',
                    ),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          backgroundColor: kPurpleColor,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                getTranslated(context, 'Verify OTP'),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        TextButton(
          onPressed: _canResend ? _resendOTP : null,
          child: Text(
            _canResend
                ? getTranslated(context, "Didn't receive the OTP? Resend")
                : translateWithPlaceholder(
                    context,
                    "Resend OTP in {time} s",
                    {"{time}": _resendCounter.toString()},
                  ),
            style: TextStyle(
              color: _canResend ? Colors.blueAccent : Colors.grey,
            ),
          ),
        ),
        if (!_canResend)
          Text(
            translateWithPlaceholder(
              context,
              "You can resend the OTP after {time} seconds",
              {"{time}": _resendCounter.toString()},
            ),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // To make the background color consistent with the theme
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: kPurpleColor),
        title: Text(
          getTranslated(context, "OTP Verification"),
          style: TextStyle(color: kPurpleColor),
          // style: TextStyle(color: Colors.black),
        ),
      ),
      body: GestureDetector(
        // To dismiss the keyboard when tapping outside
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
              _buildResendSection(),
            ],
          ),
        ),
      ),
    );
  }
}
