import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../widgets/edit_profile_widget.dart';
import '../utils/failure_dialogue.dart';
import '../utils/global_methods.dart';
import '../utils/success_dialogue.dart';

class EditProfileScreen extends StatefulWidget {
  final String firstName;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String secondName;
  final String lastName;

  const EditProfileScreen({
    super.key,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.lastName,
    required this.secondName,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _secondNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;

  late String firstName;
  late String secondName;
  late String lastName;
  late String email;
  late String phoneNumber;
  late String country;
  late String city;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _secondNameController = TextEditingController(text: widget.secondName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _countryController = TextEditingController(text: widget.country);
    _cityController = TextEditingController(text: widget.city);

    firstName = widget.firstName;
    secondName = widget.secondName;
    lastName = widget.lastName;
    email = widget.email;
    phoneNumber = widget.phone;
    country = widget.country;
    city = widget.city;

    [
      _firstNameController,
      _secondNameController,
      _lastNameController,
      _emailController,
      _phoneController,
      _countryController,
      _cityController,
    ].forEach((c) => c.addListener(_onTextChanged));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isChanged = _firstNameController.text != widget.firstName ||
          _secondNameController.text != widget.secondName ||
          _lastNameController.text != widget.lastName ||
          _emailController.text != widget.email ||
          _phoneController.text != widget.phone ||
          _countryController.text != widget.country ||
          _cityController.text != widget.city;
    });
  }

  Future<void> saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    final newPhone = _phoneController.text.trim();
    if (newPhone != widget.phone) {
      // Show loading until OTP dialog appears
      showCustomLoadingDialog(context);
      final taken = await _checkPhoneExists(newPhone);
      if (taken) {
        Navigator.pop(context); // hide loading
        _showFailure(
          "This phone number is already in use",
          'Please choose a different number',
        );
        return;
      }
      await _verifyAndUpdatePhone();
    } else {
      await _updateUserDB();
      Navigator.pop(context, true);
    }
  }

  Future<bool> _checkPhoneExists(String phone) async {
    final ref = FirebaseDatabase.instance.ref().child('App').child('User');
    final snapshot = await ref.get();
    if (!snapshot.exists) return false;
    final data = snapshot.value;
    if (data is! Map) return false;
    final currentId = FirebaseAuth.instance.currentUser?.uid;
    for (final entry in data.entries) {
      final key = entry.key;
      final userMap = entry.value;
      if (userMap is Map &&
          userMap['PhoneNumber'] == phone &&
          key != currentId) {
        return true;
      }
    }
    return false;
  }

  Future<void> _verifyAndUpdatePhone() async {
    final newPhone = _phoneController.text.trim();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: newPhone,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential cred) async {
        Navigator.pop(context); // hide loading
        try {
          await FirebaseAuth.instance.currentUser?.updatePhoneNumber(cred);
          await _updateUserDB();
          // Show success dialog then pop screen
          showDialog(
            context: context,
            builder: (_) => SuccessDialog(
              text: 'Phone Updated',
              text1: 'Your phone number has been updated successfully.',
            ),
          ).then((_) => Navigator.pop(context, true));
        } on FirebaseAuthException catch (e) {
          final rawError = e.message ?? e.code;
          _showFailure(
            'Verification failed.',
            rawError,
          );
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        Navigator.pop(context); // hide loading
        String title;
        String detail;

        switch (e.code) {
          case 'invalid-phone-number':
            title = "Invalid Phone Number";
            detail = 'Use country code such as +966XXXX';
            break;
          case 'quota-exceeded':
            title = 'Too many requests';
            detail = 'Please wait and try again later.';
            break;
          case 'missing-phone-number':
            title = 'No Number Provided';
            detail =
                'Please enter a phone number to receive the verification code.';
            break;
          default:
            title = 'Verification failed.';
            detail = e.message ?? 'Please try again later';
        }

        _showFailure(title, detail);
      },
      codeSent: (String verificationId, int? _) {
        Navigator.pop(context); // hide loading
        _showSmsCodeDialog(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {
        Navigator.pop(context); // hide loading
        _showFailure(
          'OTP Expired',
          'The code has expired – please resend.',
        );
      },
    );
  }

  void _showSmsCodeDialog(String verificationId) {
    String smsCode = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(getTranslated(context, "Enter OTP Code")),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: getTranslated(context, "OTP Code"),
          ),
          onChanged: (v) => smsCode = v.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(getTranslated(context, "Cancel")),
          ),
          TextButton(
            onPressed: () async {
              final cred = PhoneAuthProvider.credential(
                verificationId: verificationId,
                smsCode: smsCode,
              );
              try {
                await FirebaseAuth.instance.currentUser
                    ?.updatePhoneNumber(cred);
                await _updateUserDB();
                Navigator.of(context).pop(); // close OTP dialog
                showDialog(
                  context: context,
                  builder: (_) => SuccessDialog(
                    text: 'Phone Updated',
                    text1: 'Your phone number has been updated successfully.',
                  ),
                ).then((_) => Navigator.pop(context, true));
              } on FirebaseAuthException catch (e) {
                final rawError = e.message ?? e.code;
                _showFailure(
                  'Verification failed.',
                  'Wrong Otp Code Entered. Please enter the correct Otp.',
                );
              }
            },
            child: Text(getTranslated(context, "Confirm")),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserDB() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final userRef = FirebaseDatabase.instance
        .ref()
        .child('App')
        .child('User')
        .child(userId);
    await userRef.update({
      'FirstName': _firstNameController.text.trim(),
      'SecondName': _secondNameController.text.trim(),
      'LastName': _lastNameController.text.trim(),
      'Email': _emailController.text.trim(),
      'PhoneNumber': _phoneController.text.trim(),
      'Country': _countryController.text.trim(),
      'City': _cityController.text.trim(),
    });
  }

  void _showFailure(String text, String text1) {
    showDialog(
      context: context,
      builder: (_) => FailureDialog(text: text, text1: text1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        centerTitle: true,
        title: Text(
          getTranslated(context, "Edit Profile"),
          style: TextStyle(color: kDeepPurpleColor),
        ),
        actions: [
          TextButton(
            onPressed: _isChanged ? saveProfileData : null,
            child: Text(
              getTranslated(context, "Save"),
              style: TextStyle(
                color: _isChanged ? kDeepPurpleColor : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(children: [
              EditScreenTextFormField(
                controller: _firstNameController,
                labelText: getTranslated(context, "First Name"),
                onChanged: (v) => firstName = v,
                validator: (v) => v!.isEmpty
                    ? getTranslated(context, "First name must not be empty")
                    : null,
              ),
              EditScreenTextFormField(
                controller: _secondNameController,
                labelText: getTranslated(context, "Second Name"),
                onChanged: (v) => secondName = v,
                validator: (v) => v!.isEmpty
                    ? getTranslated(context, "Second name must not be empty")
                    : null,
              ),
              EditScreenTextFormField(
                controller: _lastNameController,
                labelText: getTranslated(context, "Last Name"),
                onChanged: (v) => lastName = v,
                validator: (v) => v!.isEmpty
                    ? getTranslated(context, "Last name must not be empty")
                    : null,
              ),
              EditScreenTextFormField(
                controller: _emailController,
                labelText: getTranslated(context, "Email"),
                onChanged: (v) => email = v,
                validator: (v) => v!.isEmpty
                    ? getTranslated(context, "Email must not be empty")
                    : null,
              ),
              EditScreenTextFormField(
                controller: _phoneController,
                labelText: getTranslated(context, "Phone"),
                onChanged: (v) => phoneNumber = v,
                validator: (v) => v!.isEmpty
                    ? getTranslated(context, "Phone Number must not be empty")
                    : null,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
