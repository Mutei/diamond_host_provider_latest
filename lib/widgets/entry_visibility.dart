import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../localization/language_constants.dart';

class EntryVisibility extends StatefulWidget {
  final bool isVisible;
  final Function(bool, String) onCheckboxChanged;
  final List<String> selectedEntries; // Add selectedEntries to the widget

  const EntryVisibility({
    super.key,
    required this.isVisible,
    required this.onCheckboxChanged,
    required this.selectedEntries,
  });

  @override
  _EntryVisibilityState createState() => _EntryVisibilityState();
}

class _EntryVisibilityState extends State<EntryVisibility> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return Container();

    return Column(
      children: [
        _buildCheckboxRow(
          context,
          'Familial',
          widget.selectedEntries
              .contains('Familial'), // Check if Familial is selected
          (value) {
            widget.onCheckboxChanged(value, 'Familial');
          },
        ),
        _buildCheckboxRow(
          context,
          'Single2',
          widget.selectedEntries
              .contains('Single'), // Check if Single is selected
          (value) {
            widget.onCheckboxChanged(value, 'Single');
          },
        ),
        _buildCheckboxRow(
          context,
          'mixed',
          widget.selectedEntries
              .contains('mixed'), // Check if mixed is selected
          (value) {
            widget.onCheckboxChanged(value, 'mixed');
          },
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(BuildContext context, String label, bool value,
      Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            getTranslated(context, label),
          ),
        ),
        Expanded(
          child: Checkbox(
            checkColor: Colors.white,
            activeColor: kPurpleColor,
            value: value,
            onChanged: (bool? newValue) => onChanged(newValue!),
          ),
        ),
      ],
    );
  }
}
