import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/language_constants.dart';
import '../main.dart';
import '../state_management/general_provider.dart';

// Global method to display an error alert dialog
void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          getTranslated(context, "Login Failed"),
          style: TextStyle(
            color: kErrorColor,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              getTranslated(context, "OK"),
              style: kSecondaryStyle,
            ),
          ),
        ],
      );
    },
  );
}

void showLoginErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          getTranslated(context, "Access Denied"),
          style: TextStyle(
            color: kErrorColor,
          ),
        ),
        content: Text(getTranslated(context, message)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              getTranslated(context, "OK"),
              style: kSecondaryStyle,
            ),
          ),
        ],
      );
    },
  );
}

void showLogoutConfirmationDialog(BuildContext context, Function onConfirm) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          getTranslated(context, "Confirm Logout"),
          style: TextStyle(
            color: kConfirmColor, // Customize as needed
          ),
        ),
        content:
            Text(getTranslated(context, "Are you sure you want to log out?")),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text(
              getTranslated(context, "Cancel"),
              style: TextStyle(color: Colors.grey), // Customize as needed
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog first
              onConfirm(); // Then trigger the logout
            },
            child: Text(
              getTranslated(context, "Logout"),
              style: TextStyle(color: kConfirmColor), // Customize as needed
            ),
          ),
        ],
      );
    },
  );
}

pickImage(ImageSource source) async {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _file = await _imagePicker.pickImage(source: source);
  if (_file != null) {
    return await _file.readAsBytes();
  }
  print("No image is selected!");
}

showSnackBar(String content, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content),
    ),
  );
}

void showCustomLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent, // Makes the background transparent
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              // Customize your background color
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kDeepPurpleColor),
                  strokeWidth: 6.0, // Thicker stroke for uniqueness
                ),
                const SizedBox(height: 20),
                Text(
                  getTranslated(context, 'Loading, please wait...'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
