import 'package:flutter/material.dart';

class EditScreenTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  const EditScreenTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
      ),
    );
  }
}
