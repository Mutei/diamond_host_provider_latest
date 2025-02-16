import 'package:flutter/material.dart';

import '../localization/language_constants.dart';

class ReusedProviderEstateContainer extends StatelessWidget {
  final String hint;
  const ReusedProviderEstateContainer({
    super.key,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 105, right: 20, bottom: 20, top: 10),
      child: Text(
        getTranslated(context, hint),
        // ignore: prefer_const_constructors
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
