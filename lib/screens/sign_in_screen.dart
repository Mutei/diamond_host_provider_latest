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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // New Confirm Password controller
  final TextEditingController _agentCodeController =
      TextEditingController(); // New Agent Code controller
  String? _phoneNumber;
  bool _acceptedTerms = false;

  final AuthenticationMethods _authMethods = AuthenticationMethods();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _agentCodeController.dispose();
    super.dispose();
  }

  Future<void> _launchTermsUrl() async {
    const url = 'https://www.diamondstel.com/Home/privacypolicy';
    try {
      bool launched = await launch(url, forceWebView: false);
      print('Launch successful: $launched');
    } catch (e) {
      print('Error launching maps: $e');
    }
  }

  /// Function to generate a password that meets the required criteria:
  /// - At least 8 characters
  /// - Contains at least 1 uppercase letter
  /// - Contains at least 1 special character
  String generatePassword() {
    const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String specialChars = '!@#\$&*~';

    final rand = Random.secure();
    String password = '';

    // Ensure at least 1 uppercase letter
    password += upperCase[rand.nextInt(upperCase.length)];

    // Ensure at least 1 lowercase letter
    password += lowerCase[rand.nextInt(lowerCase.length)];

    // Ensure at least 1 number
    password += numbers[rand.nextInt(numbers.length)];

    // Ensure at least 1 special character
    password += specialChars[rand.nextInt(specialChars.length)];

    // Fill the rest with random characters to make it at least 8 characters
    const allChars = upperCase + lowerCase + numbers + specialChars;
    int remainingLength = 8 - password.length;
    for (int i = 0; i < remainingLength; i++) {
      password += allChars[rand.nextInt(allChars.length)];
    }

    // Shuffle the characters to ensure randomness
    List<String> passwordChars = password.split('');
    passwordChars.shuffle(rand);
    return passwordChars.join();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.language, color: kPurpleColor),
      //       onPressed: () {
      //         showDialog(
      //           context: context,
      //           builder: (BuildContext context) {
      //             return const LanguageDialogWidget();
      //           },
      //         );
      //       },
      //     ),
      //   ],
      // ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: MediaQuery.of(context).size.height *
                      0.05, // Adjust dynamically
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
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const LanguageDialogWidget();
                              },
                            );
                          },
                          child: const Icon(Icons.language,
                              color: Colors.white, size: 30),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text(
                      getTranslated(context, "Let’s Create"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ), // Adjust dynamically
                    Center(
                      child: Column(
                        children: [
                          Text(
                            getTranslated(context, "Your Account"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Email Field
                      ReusedTextFormField(
                        controller: _emailController,
                        hintText: getTranslated(context, 'Email'),
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return getTranslated(
                                context, 'Please enter your email');
                          }
                          // You can add more email validation if needed
                          return null;
                        },
                      ),
                      20.kH,
                      // Password Field
                      ReusedTextFormField(
                        controller: _passwordController,
                        hintText: getTranslated(context, 'Password'),
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        onGeneratePassword: () {
                          setState(() {
                            String newPassword = generatePassword();
                            _passwordController.text = newPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return getTranslated(
                                context, 'Please enter your password');
                          }
                          if (!_authMethods.validatePassword(value)) {
                            return getTranslated(
                                context, 'Password does not meet criteria');
                          }
                          return null;
                        },
                      ),
                      20.kH,
                      // Retype Password Field
                      ReusedTextFormField(
                        controller: _confirmPasswordController,
                        hintText: getTranslated(context, 'Retype Password'),
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return getTranslated(context, 'Retype Password');
                          }
                          if (value != _passwordController.text) {
                            return getTranslated(
                                context, 'Passwords do not match');
                          }
                          return null;
                        },
                      ),
                      20.kH,
                      // Phone Number Field
                      ReusedPhoneNumberField(
                        onPhoneNumberChanged: (phone) {
                          setState(() {
                            _phoneNumber = phone;
                          });
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) {
                            return getTranslated(
                                context, 'Please enter a valid phone number');
                          }
                          return null;
                        },
                      ),
                      20.kH,
                      // Agent Code Field
                      ReusedTextFormField(
                        controller: _agentCodeController,
                        hintText: getTranslated(context, 'Agent Code'),
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.text,
                      ),
                      10.kH,
                      // Terms and Conditions Checkbox
                      CheckboxListTile(
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptedTerms = value!;
                          });
                        },
                        title: RichText(
                          text: TextSpan(
                            text: getTranslated(context, 'I accept the '),
                            // style: Theme.of(context).textTheme.bodyLarge,
                            style: TextStyle(color: kPrimaryColor),
                            children: <TextSpan>[
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
                                  ..onTap = () {
                                    _launchTermsUrl();
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sign in Button
                      CustomButton(
                        text: getTranslated(context, 'Sign in'),
                        onPressed: () async {
                          FocusScope.of(context).unfocus();

                          if (_formKey.currentState!.validate()) {
                            if (!_acceptedTerms) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(getTranslated(context,
                                      'Please accept the terms and conditions')),
                                ),
                              );
                              return;
                            }

                            try {
                              await _authMethods.signUpWithEmailPhone(
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                                phone: _phoneNumber!,
                                acceptedTerms: _acceptedTerms,
                                agentCode: _agentCodeController.text
                                    .trim(), // Pass Agent Code
                                context: context,
                              );
                              print('OTP sent for verification');
                            } catch (e) {
                              print('Sign-up failed: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(getTranslated(
                                      context, 'Sign-up failed: $e')),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      20.kH,
                      // Navigate to Login Screen
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
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
