// shimmer_loading_widget.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoadingWidget extends StatelessWidget {
  const ShimmerLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 20),
            Container(
              width: 200,
              height: 20,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 10),
            Container(
              width: 150,
              height: 20,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 10),
            Container(
              width: 100,
              height: 20,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }
}
