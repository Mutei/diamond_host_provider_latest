import 'package:flutter/animation.dart';

class Additional {
  late String id, name, nameEn, price = "120";
  bool isBool = false;
  Color color;
  Additional({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.price,
    required this.isBool,
    required this.color,
  });
}