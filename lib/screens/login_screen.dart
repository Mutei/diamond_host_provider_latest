import 'package:daimond_host_provider/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:daimond_host_provider/widgets/reused_textform_field.dart';
import 'package:daimond_host_provider/widgets/reused_phone_number_widget.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/widgets/reused_elevated_button.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../backend/login_method.dart';
import '../localization/language_constants.dart';
import '../widgets/language_translator_widget.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String initialCountry = 'SA';
  PhoneNumber number = PhoneNumber(isoCode: 'SA');
  PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _phoneNumber;
  final LoginMethod _loginMethod = LoginMethod();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with two-tone color
          Column(
            children: [
              Expanded(flex: 2, child: Container(color: Colors.grey.shade200)),
              Expanded(flex: 1, child: Container(color: kPrimaryColor)),
            ],
          ),

          // Foreground content (logo + form)
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Logo with Rotated Square Shadow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: -0.25, // Slight rotation
                              child: Container(
                                height: 230,
                                width: 230,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  // borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/images/logo.png',
                              height: 200,
                              width: 200,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Login Form Container
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Tabs (Email & Phone)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _pageController.animateToPage(
                                            0,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                width: 2.0,
                                                color: _currentIndex == 0
                                                    ? kPrimaryColor
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            getTranslated(
                                                context, 'Email & Password'),
                                            textAlign: TextAlign.center,
                                            style: kSecondaryStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _pageController.animateToPage(
                                            1,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                width: 2.0,
                                                color: _currentIndex == 1
                                                    ? kPrimaryColor
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            getTranslated(
                                                context, 'Phone Number'),
                                            textAlign: TextAlign.center,
                                            style: kSecondaryStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // PageView for Login Forms
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.45,
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentIndex = index;
                                      });
                                    },
                                    children: [
                                      Column(
                                        children: [
                                          ReusedTextFormField(
                                            hintText:
                                                getTranslated(context, 'Email'),
                                            prefixIcon: Icons.email,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            controller: _emailController,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return getTranslated(context,
                                                    'Please enter your email');
                                              }
                                              if (!RegExp(
                                                      r'^[^@]+@[^@]+\.[^@]+')
                                                  .hasMatch(value)) {
                                                return getTranslated(context,
                                                    'Please enter a valid email address');
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          ReusedTextFormField(
                                            controller: _passwordController,
                                            hintText: getTranslated(
                                                context, 'Password'),
                                            prefixIcon:
                                                LineAwesome.user_lock_solid,
                                            obscureText: true,
                                            validator: (value) {
                                              if (_currentIndex == 0) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return getTranslated(context,
                                                      'Please enter your password');
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          CustomButton(
                                            text:
                                                getTranslated(context, 'Login'),
                                            onPressed: () {
                                              FocusScope.of(context).unfocus();
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                _loginMethod.loginWithEmail(
                                                  email: _emailController.text
                                                      .trim(),
                                                  password: _passwordController
                                                      .text
                                                      .trim(),
                                                  context: context,
                                                );
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const ForgotPasswordScreen()),
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                Text(
                                                  getTranslated(context,
                                                      'Forgot Password?'),
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(getTranslated(context,
                                                        "Are you new here? ")),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const SignInScreen()),
                                                        );
                                                      },
                                                      child: Text(
                                                        getTranslated(
                                                            context, "Sign in"),
                                                        style: const TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Phone Number Login
                                      Column(
                                        children: [
                                          ReusedPhoneNumberField(
                                            onPhoneNumberChanged: (phone) {
                                              setState(() {
                                                _phoneNumber = phone;
                                              });
                                            },
                                            validator: (phone) {
                                              if (_currentIndex == 1) {
                                                if (phone == null ||
                                                    phone.number.isEmpty) {
                                                  return getTranslated(context,
                                                      'Please enter a valid phone number');
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          CustomButton(
                                            text: getTranslated(context,
                                                'Login through phone number'),
                                            onPressed: () {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                _loginMethod.loginWithPhone(
                                                  phoneNumber: _phoneNumber!,
                                                  context: context,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
            },
          ),
        ],
      ),
    );
  }
}
