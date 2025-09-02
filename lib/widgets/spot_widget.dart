// lib/widgets/spot_widget.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/furniture_spot.dart';

typedef VoidCallback = void Function();

class SpotWidget extends StatefulWidget {
  final FurnitureSpot spot;
  final List<FurnitureSpot> allSpots; // sibling list for collision checks
  final Size canvasSize;
  final Offset offset;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const SpotWidget({
    Key? key,
    required this.spot,
    required this.allSpots,
    required this.canvasSize,
    required this.offset,
    this.isSelected = false,
    this.onSelect,
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
    _updateDaytime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateDaytime();
    });
  }

  void _updateDaytime() {
    final hour = DateTime.now().hour;
    final isDay = hour >= 6 && hour < 18;
    if (isDay != _isDaytime) {
      setState(() => _isDaytime = isDay);
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

    final containerW =
        (spot.type == FurnitureType.table || spot.type == FurnitureType.bar)
            ? tw
            : size;
    final containerH =
        (spot.type == FurnitureType.table || spot.type == FurnitureType.bar)
            ? th
            : size;

    final iconSize = size * 0.6;
    final highContrast = spot.color.computeLuminance() > 0.5;
    final fgColor = highContrast ? Colors.black : Colors.white;

    final left =
        widget.offset.dx + spot.x * widget.canvasSize.width - containerW / 2;
    final top =
        widget.offset.dy + spot.y * widget.canvasSize.height - containerH / 2;

    Widget content;
    switch (spot.type) {
      case FurnitureType.bar:
        content = _buildBar(containerW, containerH, fgColor);
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
      case FurnitureType.screen:
        content = _buildScreen(containerW, containerH, fgColor);
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
        onTap: widget.onSelect,
        onPanStart: (_) => widget.onUpdate(),
        onPanUpdate: _handlePan,
        onLongPressStart: (details) => _showOptions(
          context,
          TapDownDetails(globalPosition: details.globalPosition),
        ),
        child: Container(
          decoration: widget.isSelected
              ? BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 3),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Transform.rotate(
            angle: widget.spot.rotation,
            child: content,
          ),
        ),
      ),
    );
  }

  /// Check if moving to (newX,newY) would overlap another spot
  bool _wouldOverlap(double newX, double newY) {
    for (final s in widget.allSpots) {
      if (s.id == widget.spot.id) continue;
      final dx = (newX - s.x).abs();
      final dy = (newY - s.y).abs();
      final halfW = (widget.spot.w + s.w) / 2;
      final halfH = (widget.spot.h + s.h) / 2;
      if (dx < halfW && dy < halfH) return true;
    }
    return false;
  }

  void _handlePan(DragUpdateDetails d) {
    final newX =
        (widget.spot.x + d.delta.dx / widget.canvasSize.width).clamp(0.0, 1.0);
    final newY =
        (widget.spot.y + d.delta.dy / widget.canvasSize.height).clamp(0.0, 1.0);

    if (!_wouldOverlap(newX, newY)) {
      setState(() {
        widget.spot.x = newX;
        widget.spot.y = newY;
      });
      widget.onUpdate();
    }
  }

  void _handleSeatPan(DragUpdateDetails d) => _handlePan(d);

  // -- SHAPE DEFINITIONS --

  Widget _buildBar(double w, double h, Color fgColor) {
    final shape = widget.spot.shape == TableShape.circle
        ? const CircleBorder()
        : widget.spot.shape == TableShape.oval
            ? const StadiumBorder()
            : widget.spot.shape == TableShape.square
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                : const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  );
    return Material(
      elevation: 2,
      shape: shape,
      color: widget.spot.color,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Bar',
            style: TextStyle(
              fontSize: math.min(w, h) * 0.4,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(double w, double h, Color fgColor) {
    // A TV-like rectangular panel with a thin bevel
    return Material(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      color: Colors.black87,
      child: Stack(
        children: [
          // Screen glass (slightly lighter inside)
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(Icons.tv,
                    color: Colors.white, size: math.min(w, h) * 0.55),
              ),
            ),
          ),
          // Small LED dot at the bottom-left
          // Positioned(
          //   left: 6,
          //   bottom: 4,
          //   child: Container(
          //     width: 6,
          //     height: 6,
          //     decoration: BoxDecoration(
          //       color: Colors.redAccent,
          //       borderRadius: BorderRadius.circular(3),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildTable(double size, Color fgColor) {
    final shape = widget.spot.shape == TableShape.circle
        ? const CircleBorder()
        : widget.spot.shape == TableShape.oval
            ? const StadiumBorder()
            : widget.spot.shape == TableShape.square
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                : const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  );
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
            color: fgColor,
          ),
        ),
      ),
    );
  }

  // -- OTHER CONTENT RENDERERS --

  Widget _buildDecoration(double w, double h, double iconSize) {
    if (widget.spot.decorationType == DecorationType.window) {
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
          child: Icon(iconData, size: iconSize, color: widget.spot.color)),
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
          onTap: widget.onSelect,
          onPanUpdate: _handleSeatPan,
          onLongPressStart: (details) => _showOptions(
            context,
            TapDownDetails(globalPosition: details.globalPosition),
          ),
          child: Container(
            decoration: widget.isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 3),
                    borderRadius: BorderRadius.circular(iconSize * 0.2),
                  )
                : null,
            child: Transform.rotate(
              angle: widget.spot.rotation,
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
            onTap: widget.onSelect,
            onPanUpdate: _handlePan,
            onLongPressStart: (details) => _showOptions(
              context,
              TapDownDetails(globalPosition: details.globalPosition),
            ),
            child: Container(
              decoration: widget.isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child:
                  Transform.rotate(angle: widget.spot.rotation, child: content),
            ),
          ),
        ),
        ...seats,
      ],
    );
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
            child: Text(getTranslated(context, 'Change Color'))),
        PopupMenuItem(
            value: 'delete', child: Text(getTranslated(context, 'Delete'))),
        PopupMenuItem(
            value: 'increase',
            child: Text(getTranslated(context, 'Increase Size'))),
        PopupMenuItem(
            value: 'decrease',
            child: Text(getTranslated(context, 'Decrease Size'))),
        PopupMenuItem(
            value: 'rotateRight',
            child: Text(getTranslated(context, 'Rotate Right'))),
        PopupMenuItem(
            value: 'rotateLeft',
            child: Text(getTranslated(context, 'Rotate Left'))),
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
      case 'rotateRight':
        _rotate(math.pi / 2);
        break;
      case 'rotateLeft':
        _rotate(-math.pi / 2);
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
                      color: c, border: Border.all(color: Colors.black26)),
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

  void _rotate(double delta) {
    setState(() {
      widget.spot.rotation = (widget.spot.rotation + delta) % (2 * math.pi);
    });
    widget.onUpdate();
  }
}
