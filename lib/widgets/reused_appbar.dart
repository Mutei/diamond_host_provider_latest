import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class ReusedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final List<Widget>? actions; // Optional actions parameter

  const ReusedAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.actions, // Initialize actions as optional
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: kDeepPurpleColor),
      ),
      centerTitle: centerTitle,
      iconTheme: kIconTheme,
      actions: actions, // Add actions to AppBar if not null
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
