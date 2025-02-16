import 'package:flutter/material.dart';

import '../localization/language_constants.dart';
import '../widgets/welcome_screen_widgets.dart'; // Import the new file

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                buildPage(
                  image: 'assets/images/p1.png',
                  text: getTranslated(context,
                      "Show what distinguishes your facility with its finest services And with its special offers and exclusives"),
                  context: context,
                ),
                buildPage(
                  image: 'assets/images/p2.png',
                  text: getTranslated(context,
                      "Enjoy arranging your appointments and easy access for clients"),
                  context: context,
                ),
                buildPage(
                  image: 'assets/images/p3.png',
                  text: getTranslated(context,
                      "We also provide the finest and best services with Premium and Premium Plus"),
                  isLastPage: true,
                  context: context,
                ),
              ],
            ),
          ),
          buildIndicator(_currentIndex, 3),
        ],
      ),
    );
  }
}
