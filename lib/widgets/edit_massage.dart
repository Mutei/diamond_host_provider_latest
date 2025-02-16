// File: edit_kids_area.dart

import 'package:flutter/material.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import '../localization/language_constants.dart';

/// Widget to edit the Kids Area availability
class EditMassage extends StatelessWidget {
  final bool isVisible;
  final bool hasMassage;
  final Function(bool isChecked) onCheckboxChanged;

  const EditMassage({
    required this.isVisible,
    required this.hasMassage,
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
              getTranslated(context, "Is there Massage?"),
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Checkbox(
            value: hasMassage,
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
