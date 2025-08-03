// import 'dart:math' as math;
// import 'package:daimond_host_provider/localization/language_constants.dart';
// import 'package:flutter/material.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import '../models/furniture_spot.dart';
//
// typedef VoidCallback = void Function();
//
// class SpotWidget extends StatelessWidget {
//   final FurnitureSpot spot;
//   final Size canvasSize;
//   final VoidCallback onUpdate;
//   final VoidCallback onDelete;
//
//   const SpotWidget({
//     super.key,
//     required this.spot,
//     required this.canvasSize,
//     required this.onUpdate,
//     required this.onDelete,
//   });
//
//   Future<void> _pickColor(BuildContext context) async {
//     final color = await showDialog<Color>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(getTranslated(context, 'Change Color')),
//         content: SingleChildScrollView(
//           child: Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: Colors.primaries.map((c) {
//               return GestureDetector(
//                 onTap: () => Navigator.of(ctx).pop(c),
//                 child: Container(
//                   width: 30,
//                   height: 30,
//                   decoration: BoxDecoration(
//                     color: c,
//                     border: Border.all(color: Colors.black26),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//     if (color != null) {
//       spot.color = color;
//       onUpdate();
//     }
//   }
//
//   void _changeSize(double factor) {
//     spot.w = (spot.w * factor).clamp(0.05, 1.0);
//     spot.h = (spot.h * factor).clamp(0.05, 1.0);
//     onUpdate();
//   }
//
//   void _showOptions(BuildContext context, TapDownDetails details) async {
//     final choice = await showMenu<String>(
//       context: context,
//       position: RelativeRect.fromLTRB(
//         details.globalPosition.dx,
//         details.globalPosition.dy,
//         details.globalPosition.dx,
//         details.globalPosition.dy,
//       ),
//       items: [
//         PopupMenuItem(
//             value: 'color',
//             child: Text(getTranslated(context, 'Change Color'))),
//         // PopupMenuItem(value: 'increase', child: Text('Increase Size')),
//         // PopupMenuItem(value: 'decrease', child: Text('Decrease Size')),
//         PopupMenuItem(
//             value: 'delete', child: Text(getTranslated(context, 'Delete'))),
//       ],
//     );
//     switch (choice) {
//       case 'color':
//         await _pickColor(context);
//         break;
//       case 'increase':
//         _changeSize(1.1);
//         break;
//       case 'decrease':
//         _changeSize(0.9);
//         break;
//       case 'delete':
//         onDelete();
//         break;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double tw = spot.w * canvasSize.width;
//     final double th = spot.h * canvasSize.height;
//     final double size = math.min(tw, th);
//     final double containerW = spot.type == FurnitureType.table ? tw : size;
//     final double containerH = spot.type == FurnitureType.table ? th : size;
//     final double iconSize = size * 0.6;
//     final bool highContrast = spot.color.computeLuminance() > 0.5;
//     final Color fgColor = highContrast ? Colors.black : Colors.white;
//
//     final double left = spot.x * canvasSize.width - containerW / 2;
//     final double top = spot.y * canvasSize.height - containerH / 2;
//
//     // build content based on spot.type (same as before)...
//     Widget content;
//     switch (spot.type) {
//       case FurnitureType.bar:
//         content = Material(
//           elevation: 2,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           color: spot.color,
//           child: Center(
//             child: Text('Bar',
//                 style: TextStyle(color: fgColor, fontWeight: FontWeight.bold)),
//           ),
//         );
//         break;
//       case FurnitureType.decoration:
//         IconData iconData;
//         switch (spot.decorationType!) {
//           case DecorationType.window:
//             iconData = MdiIcons.windowOpenVariant;
//             break;
//           case DecorationType.view:
//             iconData = MdiIcons.panorama;
//             break;
//           default:
//             iconData = MdiIcons.doorOpen;
//         }
//         content = Material(
//           elevation: 2,
//           shape: const CircleBorder(),
//           color: Colors.white,
//           child:
//               Center(child: Icon(iconData, size: iconSize, color: spot.color)),
//         );
//         break;
//       case FurnitureType.toilet:
//         content = Material(
//           elevation: 2,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           color: Colors.white,
//           child: Center(
//               child: Icon(MdiIcons.toilet, size: iconSize, color: spot.color)),
//         );
//         break;
//       case FurnitureType.seat:
//         content = Material(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(containerW * 0.1)),
//           color: spot.color,
//           child: Center(
//             child: Icon(
//               spot.seatType == SeatType.chair
//                   ? Icons.event_seat
//                   : MdiIcons.sofa,
//               size: iconSize,
//               color: fgColor,
//             ),
//           ),
//         );
//         break;
//       case FurnitureType.table:
//       default:
//         final shape = spot.shape == TableShape.circle
//             ? const CircleBorder()
//             : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
//         content = Material(
//           elevation: 2,
//           shape: shape,
//           color: spot.color,
//           child: Center(
//             child: Text(
//               '${spot.capacity}',
//               style: TextStyle(
//                   fontSize: size * 0.4,
//                   fontWeight: FontWeight.bold,
//                   color: fgColor),
//             ),
//           ),
//         );
//     }
//
//     // handle table with seat icons around
//     if (spot.type == FurnitureType.table) {
//       const seatPadding = 8.0;
//       final radius = math.max(tw, th) / 2 + iconSize / 2 + seatPadding;
//       final seats = List.generate(spot.capacity, (i) {
//         final sx = left +
//             tw / 2 +
//             radius * math.cos(2 * math.pi * i / spot.capacity) -
//             iconSize / 2;
//         final sy = top +
//             th / 2 +
//             radius * math.sin(2 * math.pi * i / spot.capacity) -
//             iconSize / 2;
//         return Positioned(
//           left: sx,
//           top: sy,
//           width: iconSize,
//           height: iconSize,
//           child: GestureDetector(
//             onPanUpdate: (d) {
//               spot.x = (spot.x + d.delta.dx / canvasSize.width).clamp(0.0, 1.0);
//               spot.y =
//                   (spot.y + d.delta.dy / canvasSize.height).clamp(0.0, 1.0);
//               onUpdate();
//             },
//             onLongPressStart: (details) => _showOptions(context,
//                 TapDownDetails(globalPosition: details.globalPosition)),
//             child: Material(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(iconSize * 0.1)),
//               color: spot.color,
//               child: Center(
//                 child: Icon(
//                   spot.seatType == SeatType.chair
//                       ? Icons.event_seat
//                       : MdiIcons.sofa,
//                   size: iconSize * 0.6,
//                   color: fgColor,
//                 ),
//               ),
//             ),
//           ),
//         );
//       });
//
//       return Stack(
//         children: [
//           Positioned(
//             left: left,
//             top: top,
//             width: containerW,
//             height: containerH,
//             child: GestureDetector(
//               onPanStart: (_) => onUpdate(),
//               onPanUpdate: (d) {
//                 spot.x =
//                     (spot.x + d.delta.dx / canvasSize.width).clamp(0.0, 1.0);
//                 spot.y =
//                     (spot.y + d.delta.dy / canvasSize.height).clamp(0.0, 1.0);
//                 onUpdate();
//               },
//               onLongPressStart: (details) => _showOptions(context,
//                   TapDownDetails(globalPosition: details.globalPosition)),
//               child: content,
//             ),
//           ),
//           ...seats,
//         ],
//       );
//     }
//
//     // other spot types
//     return Positioned(
//       left: left,
//       top: top,
//       width: containerW,
//       height: containerH,
//       child: GestureDetector(
//         onPanStart: (_) => onUpdate(),
//         onPanUpdate: (d) {
//           spot.x = (spot.x + d.delta.dx / canvasSize.width).clamp(0.0, 1.0);
//           spot.y = (spot.y + d.delta.dy / canvasSize.height).clamp(0.0, 1.0);
//           onUpdate();
//         },
//         onLongPressStart: (details) => _showOptions(
//             context, TapDownDetails(globalPosition: details.globalPosition)),
//         child: content,
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:math' as math;
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/furniture_spot.dart';

typedef VoidCallback = void Function();

/// A widget that displays furniture spots (tables, seats, decorations, etc.)
/// Includes dynamic day/night window support via timer.
class SpotWidget extends StatefulWidget {
  final FurnitureSpot spot;
  final Size canvasSize;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const SpotWidget({
    Key? key,
    required this.spot,
    required this.canvasSize,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<SpotWidget> createState() => _SpotWidgetState();
}

class _SpotWidgetState extends State<SpotWidget> {
  late Timer _timer;
  bool _isDaytime = true;

  @override
  void initState() {
    super.initState();
    // Initialize day/night based on current hour
    _updateDaytime();
    // Check every minute in case crossing threshold
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateDaytime();
    });
  }

  void _updateDaytime() {
    final hour = DateTime.now().hour;
    final isDay = hour >= 6 && hour < 18;
    if (isDay != _isDaytime) {
      setState(() {
        _isDaytime = isDay;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final tw = spot.w * widget.canvasSize.width;
    final th = spot.h * widget.canvasSize.height;
    final size = math.min(tw, th);
    final containerW = spot.type == FurnitureType.table ? tw : size;
    final containerH = spot.type == FurnitureType.table ? th : size;
    final iconSize = size * 0.6;
    final highContrast = spot.color.computeLuminance() > 0.5;
    final fgColor = highContrast ? Colors.black : Colors.white;

    final left = spot.x * widget.canvasSize.width - containerW / 2;
    final top = spot.y * widget.canvasSize.height - containerH / 2;

    Widget content;
    switch (spot.type) {
      case FurnitureType.bar:
        content = _buildBar(fgColor);
        break;
      case FurnitureType.decoration:
        content = _buildDecoration(containerW, containerH, iconSize);
        break;
      case FurnitureType.toilet:
        content = _buildToilet(iconSize);
        break;
      case FurnitureType.seat:
        content = _buildSeat(containerW, iconSize, fgColor);
        break;
      case FurnitureType.table:
      default:
        content = _buildTable(size, fgColor);
    }

    if (spot.type == FurnitureType.table) {
      return _buildTableWithSeats(
          left, top, containerW, containerH, content, iconSize);
    }

    return Positioned(
      left: left,
      top: top,
      width: containerW,
      height: containerH,
      child: GestureDetector(
        onPanStart: (_) => widget.onUpdate(),
        onPanUpdate: (d) => _handlePan(d),
        onLongPressStart: (details) => _showOptions(
          context,
          TapDownDetails(globalPosition: details.globalPosition),
        ),
        child: content,
      ),
    );
  }

  Widget _buildBar(Color fgColor) => Material(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: widget.spot.color,
        child: Center(
          child: Text('Bar',
              style: TextStyle(color: fgColor, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _buildDecoration(double w, double h, double iconSize) {
    if (widget.spot.decorationType == DecorationType.window) {
      // Day/night window SVG
      final asset = _isDaytime
          ? 'assets/images/riyadh-skyline-window.svg'
          : 'assets/images/riyadh-nightscape-window.svg';
      return SvgPicture.asset(
        asset,
        width: w * 0.8,
        height: h * 0.8,
        fit: BoxFit.contain,
      );
    }
    final iconData = widget.spot.decorationType == DecorationType.view
        ? MdiIcons.panorama
        : MdiIcons.doorOpen;
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      color: Colors.white,
      child: Center(
        child: Icon(iconData, size: iconSize, color: widget.spot.color),
      ),
    );
  }

  Widget _buildToilet(double iconSize) => Material(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.white,
        child: Center(
            child: Icon(MdiIcons.toilet,
                size: iconSize, color: widget.spot.color)),
      );

  Widget _buildSeat(double w, double iconSize, Color fgColor) => Material(
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(w * 0.1)),
        color: widget.spot.color,
        child: Center(
          child: Icon(
            widget.spot.seatType == SeatType.chair
                ? Icons.event_seat
                : MdiIcons.sofa,
            size: iconSize,
            color: fgColor,
          ),
        ),
      );

  Widget _buildTable(double size, Color fgColor) {
    final shape = widget.spot.shape == TableShape.circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    return Material(
      elevation: 2,
      shape: shape,
      color: widget.spot.color,
      child: Center(
        child: Text(
          '${widget.spot.capacity}',
          style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: fgColor),
        ),
      ),
    );
  }

  Widget _buildTableWithSeats(double left, double top, double w, double h,
      Widget content, double iconSize) {
    const seatPadding = 8.0;
    final radius = math.max(w, h) / 2 + iconSize / 2 + seatPadding;
    final seats = List.generate(widget.spot.capacity, (i) {
      final sx = left +
          w / 2 +
          radius * math.cos(2 * math.pi * i / widget.spot.capacity) -
          iconSize / 2;
      final sy = top +
          h / 2 +
          radius * math.sin(2 * math.pi * i / widget.spot.capacity) -
          iconSize / 2;
      return Positioned(
        left: sx,
        top: sy,
        width: iconSize,
        height: iconSize,
        child: GestureDetector(
          onPanUpdate: (d) => _handleSeatPan(d),
          onLongPressStart: (details) => _showOptions(
              context, TapDownDetails(globalPosition: details.globalPosition)),
          child: Material(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(iconSize * 0.1)),
            color: widget.spot.color,
            child: Center(
              child: Icon(
                widget.spot.seatType == SeatType.chair
                    ? Icons.event_seat
                    : MdiIcons.sofa,
                size: iconSize * 0.6,
                color: widget.spot.color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
        ),
      );
    });

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: w,
          height: h,
          child: GestureDetector(
            onPanUpdate: (d) => _handlePan(d),
            onLongPressStart: (details) => _showOptions(context,
                TapDownDetails(globalPosition: details.globalPosition)),
            child: content,
          ),
        ),
        ...seats,
      ],
    );
  }

  void _handlePan(DragUpdateDetails d) {
    setState(() {
      widget.spot.x = (widget.spot.x + d.delta.dx / widget.canvasSize.width)
          .clamp(0.0, 1.0);
      widget.spot.y = (widget.spot.y + d.delta.dy / widget.canvasSize.height)
          .clamp(0.0, 1.0);
    });
    widget.onUpdate();
  }

  void _handleSeatPan(DragUpdateDetails d) {
    setState(() {
      widget.spot.x = (widget.spot.x + d.delta.dx / widget.canvasSize.width)
          .clamp(0.0, 1.0);
      widget.spot.y = (widget.spot.y + d.delta.dy / widget.canvasSize.height)
          .clamp(0.0, 1.0);
    });
    widget.onUpdate();
  }

  Future<void> _showOptions(
      BuildContext context, TapDownDetails details) async {
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'color',
          child: Text(getTranslated(context, 'Change Color')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(getTranslated(context, 'Delete')),
        ),
        PopupMenuItem(
          value: 'increase',
          child: Text(getTranslated(context, 'Increase Size')),
        ),
        PopupMenuItem(
          value: 'decrease',
          child: Text(getTranslated(context, 'Decrease Size')),
        ),
      ],
    );

    switch (choice) {
      case 'color':
        await _pickColor(context);
        break;
      case 'delete':
        widget.onDelete();
        break;
      case 'increase':
        _changeSize(1.1);
        break;
      case 'decrease':
        _changeSize(0.9);
        break;
    }
  }

  Future<void> _pickColor(BuildContext context) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(getTranslated(context, 'Change Color')),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Colors.primaries.map((c) {
              return GestureDetector(
                onTap: () => Navigator.of(ctx).pop(c),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c,
                    border: Border.all(color: Colors.black26),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (color != null) {
      setState(() => widget.spot.color = color);
      widget.onUpdate();
    }
  }

  void _changeSize(double factor) {
    setState(() {
      widget.spot.w = (widget.spot.w * factor).clamp(0.05, 1.0);
      widget.spot.h = (widget.spot.h * factor).clamp(0.05, 1.0);
    });
    widget.onUpdate();
  }
}
