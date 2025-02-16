import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import 'colors.dart';

final kIconTheme = IconThemeData(
  color: kDeepPurpleColor, // Change this to your desired color
);
final kDefaultPinTheme = PinTheme(
  width: 56,
  height: 56,
  textStyle: const TextStyle(
      fontSize: 20,
      color: Color.fromRGBO(30, 60, 87, 1),
      fontWeight: FontWeight.w600),
  decoration: BoxDecoration(
    border: Border.all(
      color: const Color.fromRGBO(234, 239, 243, 1),
    ),
    borderRadius: BorderRadius.circular(20),
  ),
);
final kFocusedPinTheme = kDefaultPinTheme.copyDecorationWith(
  border: Border.all(
    color: const Color.fromRGBO(114, 178, 238, 1),
  ),
  borderRadius: BorderRadius.circular(8),
);

final kSubmittedPinTheme = kDefaultPinTheme.copyWith(
  decoration: kDefaultPinTheme.decoration?.copyWith(
    color: const Color.fromRGBO(234, 239, 243, 1),
  ),
);
ButtonStyle kElevatedButtonStyle = ElevatedButton.styleFrom(
  minimumSize: const Size(double.infinity, 36),
  backgroundColor: kPrimaryColor,
);
final kPrimaryStyle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  foreground: Paint()
    ..shader = LinearGradient(
      colors: [
        kDeepPurpleColor,
        kPurpleColor,
      ], // Increase contrast
    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
);
final kTeritary = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
  foreground: Paint()
    ..shader = LinearGradient(
      colors: [
        kDeepPurpleColor,
        kPurpleColor,
      ], // Increase contrast
    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
);

final kSecondaryStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  foreground: Paint()
    ..shader = LinearGradient(
      colors: [
        kDeepPurpleColor,
        kPurpleColor,
      ], // Increase contrast
    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
);
