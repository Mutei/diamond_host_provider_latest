import 'dart:math'; // Import for password generation
import 'package:auto_size_text/auto_size_text.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:icons_plus/icons_plus.dart'; // Import the icons_plus package

import '../backend/authentication_methods.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../state_management/general_provider.dart';
import '../utils/global_methods.dart';
import '../utils/failure_dialogue.dart';
import '../widgets/language_translator_widget.dart';
import '../widgets/reused_elevated_button.dart';
import '../widgets/reused_phone_number_widget.dart';
import '../widgets/reused_textform_field.dart';
import 'login_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _agentCodeController = TextEditingController();
  String? _phoneNumber;
  bool _acceptedTerms = false;

  final _authMethods = AuthenticationMethods();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _agentCodeController.dispose();
    super.dispose();
  }

  Future<void> _launchTermsUrl() async {
    const url = 'https://redakapp.com/terms-%26-conditions';
    try {
      await launch(url, forceWebView: false);
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  String generatePassword() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const nums = '0123456789';
    const specs = '!@#\$&*~';
    final rand = Random.secure();
    var pwd = '';
    pwd += upper[rand.nextInt(upper.length)];
    pwd += lower[rand.nextInt(lower.length)];
    pwd += nums[rand.nextInt(nums.length)];
    pwd += specs[rand.nextInt(specs.length)];
    const all = upper + lower + nums + specs;
    while (pwd.length < 8) {
      pwd += all[rand.nextInt(all.length)];
    }
    final chars = pwd.split('')..shuffle(rand);
    return chars.join();
  }

  /// Simple regex-based validation for E.164 & Saudi mobile
  Future<String?> _preValidateNumber(String raw) async {
    final e164 = RegExp(r'^\+\d{8,15}$');
    if (!e164.hasMatch(raw)) {
      return getTranslated(
        context,
        'Please enter in E.164 format, e.g. +9665XXXXXXXX',
      );
    }
    final saudi = RegExp(r'^\+9665\d{8}$');
    if (!saudi.hasMatch(raw)) {
      return getTranslated(
        context,
        'Please enter a valid Saudi mobile: +9665XXXXXXXX',
      );
    }
    _phoneNumber = raw;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Column(
            children: [
              // ===== Header =====
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: height * 0.05,
                ),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const LanguageDialogWidget(),
                          ),
                          child: const Icon(Icons.language,
                              color: Colors.white, size: 30),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    Text(
                      getTranslated(context, "Let’s Create"),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    Center(
                      child: Text(
                        getTranslated(context, "Your Account"),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 30),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Form =====
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ReusedTextFormField(
                        controller: _emailController,
                        hintText: getTranslated(context, 'Email'),
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.isEmpty)
                            ? getTranslated(context, 'Please enter your email')
                            : null,
                      ),
                      20.kH,
                      ReusedTextFormField(
                        controller: _passwordController,
                        hintText: getTranslated(context, 'Password'),
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        onGeneratePassword: () {
                          setState(() =>
                              _passwordController.text = generatePassword());
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return getTranslated(
                                context, 'Please enter your password');
                          }
                          if (!_authMethods.validatePassword(v)) {
                            return getTranslated(
                                context, 'Password Description');
                          }
                          return null;
                        },
                      ),
                      20.kH,
                      ReusedTextFormField(
                        controller: _confirmPasswordController,
                        hintText: getTranslated(context, 'Retype Password'),
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return getTranslated(context, 'Retype Password');
                          }
                          if (v != _passwordController.text) {
                            return getTranslated(
                                context, 'Passwords do not match.');
                          }
                          return null;
                        },
                      ),
                      20.kH,
                      ReusedPhoneNumberField(
                        onPhoneNumberChanged: (phone) =>
                            setState(() => _phoneNumber = phone),
                        validator: (p) => (p == null || p.number.isEmpty)
                            ? getTranslated(
                                context, 'Please enter a valid phone number')
                            : null,
                      ),
                      20.kH,
                      ReusedTextFormField(
                        controller: _agentCodeController,
                        hintText: getTranslated(context, 'Agent Code'),
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.text,
                      ),
                      10.kH,
                      CheckboxListTile(
                        value: _acceptedTerms,
                        onChanged: (v) => setState(() => _acceptedTerms = v!),
                        title: RichText(
                          text: TextSpan(
                            text: getTranslated(context, 'I accept the '),
                            style: TextStyle(color: kPrimaryColor),
                            children: [
                              TextSpan(
                                text: getTranslated(
                                    context, 'terms and conditions'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _launchTermsUrl,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ===== Sign In Button =====
                      CustomButton(
                        text: getTranslated(context, 'Sign in'),
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          if (!_formKey.currentState!.validate()) return;
                          if (!_acceptedTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(getTranslated(context,
                                    'Please accept the terms and conditions')),
                              ),
                            );
                            return;
                          }

                          final phoneError =
                              await _preValidateNumber(_phoneNumber!);
                          if (phoneError != null) {
                            await showDialog(
                              context: context,
                              builder: (_) => FailureDialog(
                                text: 'Invalid Phone Number',
                                text1: phoneError,
                              ),
                            );
                            return;
                          }

                          showCustomLoadingDialog(context);
                          try {
                            await _authMethods.signUpWithEmailPhone(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              phone: _phoneNumber!,
                              acceptedTerms: _acceptedTerms,
                              agentCode: _agentCodeController.text.trim(),
                              context: context,
                            );
                            if (Navigator.canPop(context))
                              Navigator.pop(context);
                          } catch (e) {
                            if (Navigator.canPop(context))
                              Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(getTranslated(
                                    context, 'Sign-up failed: $e')),
                              ),
                            );
                          }
                        },
                      ),
                      20.kH,

                      // ===== Navigate to Login =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: AutoSizeText(
                              getTranslated(
                                  context, "Already have an account? "),
                              style: Theme.of(context).textTheme.bodyLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                            child: Text(
                              getTranslated(context, "Login"),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
