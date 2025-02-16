import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/screens/sign_in_screen.dart';
import 'package:daimond_host_provider/widgets/reused_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/screens/login_screen.dart';

Widget buildPage({
  required String image,
  required String text,
  bool isLastPage = false,
  required BuildContext context,
}) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Image.asset(image), // Replace with correct asset path
        ),
        const SizedBox(height: 20),
        Text(
          text,
          textAlign: TextAlign.center,
          style: kSecondaryStyle,
        ),
        const SizedBox(height: 20),
        if (isLastPage)
          CustomButton(
            text: getTranslated(context, 'Next'), // Phone icon for the button
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
      ],
    ),
  );
}

Widget buildIndicator(int currentIndex, int totalPages) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          margin: const EdgeInsets.all(4.0),
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index ? kPurpleColor : Colors.grey,
          ),
        );
      }),
    ),
  );
}
