import 'package:flutter/material.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import '../localization/language_constants.dart';

/// Widget to edit the Valet Options, including valet with fees
class EditValetOptions extends StatelessWidget {
  final bool isVisible;
  final bool hasValet;
  final bool valetWithFees;
  final Function(bool isChecked) onCheckboxChanged;
  final Function(bool isChecked) onValetFeesChanged;

  const EditValetOptions({
    required this.isVisible,
    required this.hasValet,
    required this.valetWithFees,
    required this.onCheckboxChanged,
    required this.onValetFeesChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Text(getTranslated(context, "Is there valet?")),
            value: hasValet,
            onChanged: (bool? value) {
              if (value != null) {
                onCheckboxChanged(value);
              }
            },
            activeColor: kPurpleColor,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (hasValet)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  title: Text(getTranslated(context, "Valet with fees")),
                  value: valetWithFees,
                  onChanged: (bool? value) {
                    if (value != null) {
                      onValetFeesChanged(value);
                    }
                  },
                  activeColor: kPurpleColor,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (!valetWithFees)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 16.0),
                    child: Text(
                      getTranslated(context,
                          "If valet with fees is not selected, valet service is free."),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
