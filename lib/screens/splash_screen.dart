import 'dart:async';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/screens/personal_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daimond_host_provider/state_management/general_provider.dart';
import '../auth_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Define a fade-in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Define a scaling animation for the logo
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut, // Elastic effect for professional touch
      ),
    );

    // Start the animation
    _animationController.forward();

    // Navigate to the AuthHandler after the splash screen is shown
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthHandler()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Adding a gradient background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [kDarkModeColor]
                    : [Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Main content with logo and app name
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App logo
                    Container(
                      width: 150.0,
                      height: 150.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle, // Makes the box a circle
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/images/logo.png'), // Your app logo path
                          fit: BoxFit
                              .cover, // Ensures the image covers the circle
                        ),
                      ),
                    ),

                    const SizedBox(height: 20.0),

                    // App name or tagline
                    Text(
                      getTranslated(
                          context, 'Main Screen'), // Replace with your app name
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: kPurpleColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      getTranslated(context,
                          'Experience the best service'), // Optional tagline
                      style: TextStyle(
                        fontSize: 16.0,
                        color: kPurpleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
