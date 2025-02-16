import 'package:daimond_host_provider/constants/colors.dart';
import 'package:flutter/material.dart';

import '../localization/language_constants.dart';

class SessionsVisibility extends StatefulWidget {
  final bool isVisible;
  final Function(bool, String) onCheckboxChanged;
  final List<String> selectedSessions; // Accept selectedSessions

  const SessionsVisibility({
    super.key,
    required this.isVisible,
    required this.onCheckboxChanged,
    required this.selectedSessions, // Add selectedSessions parameter
  });

  @override
  _SessionsVisibilityState createState() => _SessionsVisibilityState();
}

class _SessionsVisibilityState extends State<SessionsVisibility> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return Container();

    return Column(
      children: [
        _buildCheckboxRow(
          context,
          'Internal sessions',
          widget.selectedSessions
              .contains('Internal sessions'), // Check if it's selected
          (value) {
            widget.onCheckboxChanged(value, 'Internal sessions');
          },
        ),
        _buildCheckboxRow(
          context,
          'External sessions',
          widget.selectedSessions
              .contains('External sessions'), // Check if it's selected
          (value) {
            widget.onCheckboxChanged(value, 'External sessions');
          },
        ),
        _buildCheckboxRow(
          context,
          'Private sessions',
          widget.selectedSessions
              .contains('Private sessions'), // Check if it's selected
          (value) {
            widget.onCheckboxChanged(value, 'Private sessions');
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
            value: value,
            onChanged: (bool? newValue) => onChanged(newValue!),
            activeColor: kPurpleColor,
          ),
        ),
      ],
    );
  }
}
