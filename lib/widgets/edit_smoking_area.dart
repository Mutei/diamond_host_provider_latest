// File: edit_kids_area.dart

import 'package:flutter/material.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import '../localization/language_constants.dart';

/// Widget to edit the Kids Area availability
class EditSmokingArea extends StatelessWidget {
  final bool isVisible;
  final bool hasSmokingArea;
  final Function(bool isChecked) onCheckboxChanged;

  const EditSmokingArea({
    required this.isVisible,
    required this.hasSmokingArea,
    required this.onCheckboxChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              getTranslated(context, "Is Smoking Allowed?"),
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Checkbox(
            value: hasSmokingArea,
            checkColor: Colors.white,
            onChanged: (bool? value) {
              if (value != null) {
                onCheckboxChanged(value);
              }
            },
            activeColor: kPurpleColor,
          ),
        ],
      ),
    );
  }
}
