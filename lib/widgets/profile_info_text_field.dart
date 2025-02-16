import 'package:flutter/material.dart';

class ProfileInfoTextField extends StatefulWidget {
  final TextEditingController textEditingController;
  final IconData iconData;
  final TextInputType textInputType;
  final Color iconColor;
  const ProfileInfoTextField({
    Key? key,
    required this.textEditingController,
    required this.iconData,
    required this.textInputType,
    required this.iconColor,
  }) : super(key: key);

  @override
  _ProfileInfoTextFieldState createState() => _ProfileInfoTextFieldState();
}

class _ProfileInfoTextFieldState extends State<ProfileInfoTextField> {
  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide: Divider.createBorderSide(context),
      borderRadius: BorderRadius.circular(16),
    );

    return TextField(
      controller: widget.textEditingController,
      // style: const TextStyle(
      //     color: Colors.black, // Change text color
      //     fontSize: 16,
      //     fontWeight: FontWeight.w500 // Adjust font size
      //     ),
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        prefixIcon: ColorFiltered(
          colorFilter: ColorFilter.mode(
            widget.iconColor,
            BlendMode.srcIn,
          ),
          child: Icon(widget.iconData),
        ),
        border: inputBorder,
        focusedBorder: OutlineInputBorder(
          // Change focused border style
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor, // Change border color
            width: 2.0, // Adjust border width
          ),
        ),
        enabledBorder: inputBorder,
        filled: true,
        contentPadding: const EdgeInsets.all(8),
      ),
      keyboardType: widget.textInputType,
      enabled: false,
    );
  }
}
