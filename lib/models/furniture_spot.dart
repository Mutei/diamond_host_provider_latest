// lib/models/furniture_spot.dart
import 'package:flutter/material.dart';

/// What kind of spot this is.
enum FurnitureType { table, seat, toilet, decoration, bar }

/// Shapes only for tables.
enum TableShape { rectangle, square, circle }

/// Chair vs. sofa styling.
enum SeatType { chair, sofa }

/// Decoration variants.
enum DecorationType { door, window, view }

class FurnitureSpot {
  final String id;
  double x; // normalized 0..1
  double y;
  double w; // normalized width
  double h; // normalized height

  /// table, seat, toilet, decoration, or bar
  FurnitureType type;

  /// only for tables
  int capacity;

  /// only for tables
  TableShape shape;

  /// for seats and seats around tables
  SeatType seatType;

  /// only when type == decoration
  DecorationType? decorationType;

  /// tint/color
  Color color;

  FurnitureSpot({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.type,
    this.capacity = 1,
    this.shape = TableShape.rectangle,
    this.seatType = SeatType.chair,
    this.decorationType,
    this.color = const Color(0xFFB8860B),
  });
}
