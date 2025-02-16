import 'package:flutter/material.dart';

class DrawerItem extends StatelessWidget {
  final String text;
  final Icon icon;
  final Function() onTap;
  final String hint;
  final Widget? badge;

  const DrawerItem({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.hint,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
        title: Text(text),
        subtitle: Text(
          hint,
          style: TextStyle(fontSize: 12),
        ),
        leading: badge != null ? badge : icon,
        onTap: onTap,
      ),
    );
  }
}
