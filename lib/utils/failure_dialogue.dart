import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';

class FailureDialog extends StatefulWidget {
  final String text;
  final String text1;
  const FailureDialog({super.key, required this.text, required this.text1});

  @override
  _FailureDialogState createState() => _FailureDialogState();
}

class _FailureDialogState extends State<FailureDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack);

    // Start the animation as soon as the dialog is shown
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: const Icon(
                Icons.cancel_outlined,
                color: kErrorColor,
                size: 80,
              ),
            ),
            20.kH,
            Text(
              getTranslated(context, widget.text),
              style: kSecondaryStyle,
            ),
            10.kH,
            Text(
              getTranslated(context, widget.text1),
              style: kSecondaryStyle,
              textAlign: TextAlign.center,
            ),
            20.kH,
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                getTranslated(context, 'OK'),
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
