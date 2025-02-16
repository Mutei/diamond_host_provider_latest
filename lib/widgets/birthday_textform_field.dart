import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../localization/language_constants.dart';

class TextFormFieldStyle extends StatefulWidget {
  final BuildContext context;
  final String hint;
  final Icon? icon;
  final Widget? prefixIconWidget;
  final TextEditingController control;
  bool isObsecured;
  final bool validate;
  final TextInputType textInputType;
  final FocusNode? focusNode;
  final bool showVisibilityToggle;
  final String? Function(String?)? validator; // Optional validator function

  TextFormFieldStyle({
    super.key,
    required this.context,
    required this.hint,
    this.icon,
    this.prefixIconWidget,
    required this.control,
    required this.isObsecured,
    required this.validate,
    required this.textInputType,
    this.focusNode,
    this.showVisibilityToggle = false,
    this.validator, // Optional validator
  });

  @override
  _TextFormFieldStyleState createState() => _TextFormFieldStyleState();
}

class _TextFormFieldStyleState extends State<TextFormFieldStyle> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? kDarkModeColor
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: const Offset(0, 2),
            blurRadius: 4.0,
          ),
        ],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        textAlignVertical: TextAlignVertical.center,
        controller: widget.control,
        obscureText: widget.isObsecured,
        enabled: widget.validate,
        focusNode: widget.focusNode,
        textAlign: Directionality.of(context) == TextDirection.rtl
            ? TextAlign.right
            : TextAlign.left,
        decoration: InputDecoration(
          prefixIcon: widget.prefixIconWidget ?? widget.icon,
          border: InputBorder.none,
          hintText: getTranslated(context, widget.hint),
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          suffixIcon: widget.showVisibilityToggle
              ? IconButton(
                  icon: Icon(
                    widget.isObsecured
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      widget.isObsecured = !widget.isObsecured;
                    });
                  },
                )
              : null,
        ),
        keyboardType: widget.textInputType,
        style: const TextStyle(fontFamily: "Poppins", fontSize: 16),
        validator: widget.validator, // Use the optional validator
      ),
    );
  }
}
