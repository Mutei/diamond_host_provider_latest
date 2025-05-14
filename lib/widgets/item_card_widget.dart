import 'package:flutter/material.dart';
class ItemInCard extends StatelessWidget {
  final Icon icon;
  final String data;
  final String label;
  final Widget? additionalWidget;

  ItemInCard(this.icon, this.data, this.label, {this.additionalWidget});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon.icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          if (additionalWidget != null) additionalWidget!,
        ],
      ),
    );
  }
}