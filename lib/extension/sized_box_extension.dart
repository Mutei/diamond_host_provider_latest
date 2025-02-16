import 'package:flutter/material.dart';

extension IntExtension on int? {
  int validate({int value = 0}) {
    return this ?? value;
  }

  Widget get kH => SizedBox(
        height: this?.toDouble(),
      );
  Widget get kW => SizedBox(
        width: this?.toDouble(),
      );
}
