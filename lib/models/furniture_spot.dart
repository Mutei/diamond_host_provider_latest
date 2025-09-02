import 'package:flutter/material.dart';

enum FurnitureType { table, seat, toilet, decoration, bar, screen }

enum TableShape { rectangle, square, circle, oval }

enum SeatType { chair, sofa }

enum DecorationType { door, window, view }

class FurnitureSpot {
  final String id;
  double x;
  double y;
  double w;
  double h;
  FurnitureType type;
  int capacity;
  TableShape shape;
  SeatType seatType;
  DecorationType? decorationType;
  Color color;
  double rotation;

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
    this.rotation = 0.0,
  });

  // Convert to JSON for Firebase/DB
  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'type': type.name,
        'capacity': capacity,
        'shape': shape.name,
        'seatType': seatType.name,
        'decoration': decorationType?.name,
        'color': color.value,
        'rotation': rotation,
      };

  static FurnitureSpot fromJson(Map<dynamic, dynamic> json) {
    return FurnitureSpot(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
      type: FurnitureType.values.firstWhere((e) => e.name == json['type']),
      capacity: (json['capacity'] is int)
          ? json['capacity'] as int
          : int.tryParse('${json['capacity']}') ?? 1,
      shape: TableShape.values.firstWhere((e) => e.name == json['shape'],
          orElse: () => TableShape.rectangle),
      seatType: SeatType.values.firstWhere((e) => e.name == json['seatType'],
          orElse: () => SeatType.chair),
      decorationType: json['decoration'] != null
          ? DecorationType.values
              .firstWhere((e) => e.name == json['decoration'])
          : null,
      color: Color(json['color'] as int),
      rotation: (json['rotation'] is num)
          ? (json['rotation'] as num).toDouble()
          : 0.0,
    );
  }
}
