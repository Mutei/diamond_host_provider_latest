import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/widgets/reused_appbar.dart';
import 'package:daimond_host_provider/widgets/reused_elevated_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../utils/failure_dialogue.dart';
import '../utils/success_dialogue.dart';
import '../widgets/birthday_textform_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool validateEmail = true;

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
  }

  Future<void> passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      showDialog(
        context: context,
        builder: (context) {
          return SuccessDialog(
            text: "Success",
            text1: "Password reset link sent. Check your email.",
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return FailureDialog(
            text: "Error",
            text1: e.message.toString(),
          );
        },
      );
    }
  }

  Future<void> validateAndResetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return FailureDialog(
            text: "Error",
            text1: "Please enter an email",
          );
        },
      );
      return;
    }

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref('App/User');
      DatabaseEvent event = await ref.once();

      Map<dynamic, dynamic>? users = event.snapshot.value as Map?;
      if (users != null) {
        for (var userId in users.keys) {
          Map<dynamic, dynamic> userData = users[userId];
          if (userData['Email'] == email) {
            if (userData['TypeUser'] == "2") {
              await passwordReset();
              return;
            } else {
              showDialog(
                context: context,
                builder: (context) {
                  return FailureDialog(
                    text: "Error",
                    text1: "Only providers can reset their password",
                  );
                },
              );
              return;
            }
          }
        }
        // If no matching email is found
        showDialog(
          context: context,
          builder: (context) {
            return FailureDialog(
              text: "Error",
              text1: "Email not found",
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return FailureDialog(
            text: "Error",
            text1: e.toString(),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Reset Password"),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormFieldStyle(
                context: context,
                hint: "Email",
                icon: Icon(
                  Icons.person,
                  color: kDeepPurpleColor,
                ),
                control: _emailController,
                isObsecured: false,
                validate: validateEmail,
                textInputType: TextInputType.emailAddress,
                showVisibilityToggle: false,
              ),
              20.kH,
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomButton(
                  text: getTranslated(context, "Reset Password"),
                  onPressed: () async {
                    await validateAndResetPassword();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
