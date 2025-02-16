import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ReusableIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Icon icon;
  final String label;

  const ReusableIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: kPrimaryGradient, // Use the gradient from colors.dart
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label,style: TextStyle(color: Colors.white,),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          // Make button background transparent
          shadowColor: Colors.transparent,
          // Remove shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }
}
