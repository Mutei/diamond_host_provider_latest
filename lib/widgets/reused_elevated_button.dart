import 'package:flutter/material.dart';
import '../constants/colors.dart'; // Adjust the path as needed

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: kPrimaryGradient, // Use the gradient from colors.dart
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white, // White text for better contrast
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
