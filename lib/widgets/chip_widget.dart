import 'package:daimond_host_provider/constants/colors.dart';
import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const InfoChip({
    Key? key,
    required this.icon,
    required this.label,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If onTap is provided, use an ActionChip to show the clickable effect.
    if (onTap != null) {
      return ActionChip(
        avatar: Icon(icon, color: kDeepPurpleColor, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        onPressed: onTap,
        backgroundColor: Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      );
    } else {
      return Chip(
        avatar: Icon(icon, color: kDeepPurpleColor, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      );
    }
  }
}
