import 'package:daimond_host_provider/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:icons_plus/icons_plus.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:url_launcher/url_launcher.dart';

import '../backend/login_method.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../widgets/language_translator_widget.dart';
import '../widgets/reused_elevated_button.dart';
import '../widgets/reused_phone_number_widget.dart';
import '../widgets/reused_textform_field.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String initialCountry = 'SA';
  PhoneNumber number = PhoneNumber(isoCode: 'SA');
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _phoneNumber;

  final LoginMethod _loginMethod = LoginMethod();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const LanguageDialogWidget(),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(Icons.language, color: kPrimaryColor, size: 30),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _makePhoneCall("920031542"),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.support_agent, color: kPurpleColor, size: 28),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Two-tone background
            Column(
              children: [
                Expanded(
                    flex: 2, child: Container(color: Colors.grey.shade200)),
                Expanded(flex: 1, child: Container(color: kPrimaryColor)),
              ],
            ),

            // Scrollable content
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo with rotated shadow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          height: 230,
                          width: 230,
                          decoration:
                              BoxDecoration(color: Colors.grey.shade400),
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

                  // Login form container
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
                          // Tabs
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          width: 2,
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
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          width: 2,
                                          color: _currentIndex == 1
                                              ? kPrimaryColor
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      getTranslated(context, 'Phone Number'),
                                      textAlign: TextAlign.center,
                                      style: kSecondaryStyle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // PageView
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (i) =>
                                  setState(() => _currentIndex = i),
                              children: [
                                // Email & Password
                                Column(
                                  children: [
                                    ReusedTextFormField(
                                      hintText: getTranslated(context, 'Email'),
                                      prefixIcon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      controller: _emailController,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return getTranslated(context,
                                              'Please enter your email');
                                        }
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                            .hasMatch(v)) {
                                          return getTranslated(context,
                                              'Please enter a valid email address');
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    ReusedTextFormField(
                                      controller: _passwordController,
                                      hintText:
                                          getTranslated(context, 'Password'),
                                      prefixIcon: LineAwesome.user_lock_solid,
                                      obscureText: true,
                                      validator: (v) {
                                        if ((v == null || v.isEmpty) &&
                                            _currentIndex == 0) {
                                          return getTranslated(context,
                                              'Please enter your password');
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    CustomButton(
                                      text: getTranslated(context, 'Login'),
                                      onPressed: () {
                                        FocusScope.of(context).unfocus();
                                        if (_formKey.currentState!.validate()) {
                                          _loginMethod.loginWithEmail(
                                            email: _emailController.text.trim(),
                                            password:
                                                _passwordController.text.trim(),
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
                                            builder: (_) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            getTranslated(
                                                context, 'Forgot Password?'),
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
                                                      builder: (_) =>
                                                          const SignInScreen(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  getTranslated(
                                                      context, "Sign in"),
                                                  style: const TextStyle(
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
                                  ],
                                ),

                                // Phone Number
                                Column(
                                  children: [
                                    ReusedPhoneNumberField(
                                      onPhoneNumberChanged: (phone) {
                                        setState(() => _phoneNumber = phone);
                                      },
                                      validator: (phone) {
                                        if ((phone == null ||
                                                phone.number.isEmpty) &&
                                            _currentIndex == 1) {
                                          return getTranslated(context,
                                              'Please enter a valid phone number');
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    CustomButton(
                                      text: getTranslated(context,
                                          'Login through phone number'),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
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

                  const SizedBox(height: 12),

                  // Customer App download banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent,
                            size: 28, color: kPrimaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            getTranslated(context,
                                "If you’re a customer, download our Customer App"),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            const url =
                                'https://play.google.com/store/apps/details?id=com.diamondhost.provider';
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Could not open link")),
                              );
                            }
                          },
                          icon: const Icon(Icons.get_app),
                          label: Text(getTranslated(context, "Download")),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimaryColor,
                            side: BorderSide(color: kPrimaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
