import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable shimmer loading widget with customizable icon
class CustomDrawerShimmerLoading extends StatelessWidget {
  final IconData icon; // Accepts a custom icon

  const CustomDrawerShimmerLoading({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        leading: Icon(icon, color: Colors.grey), // Use the provided icon
        title: Container(
          height: 16,
          width: 100,
          color: Colors.grey,
        ),
        subtitle: Container(
          height: 12,
          width: 150,
          color: Colors.grey,
        ),
      ),
    );
  }
}
