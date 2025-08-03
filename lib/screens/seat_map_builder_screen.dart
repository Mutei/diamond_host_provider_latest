// lib/screens/seat_map_builder_screen.dart

import 'dart:math' as math;
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/furniture_spot.dart';
import '../widgets/spot_widget.dart';
import '../widgets/tool_bar.dart';

/// A simple container for the completed layout data.
class AutoCadLayout {
  final String layoutId;
  final double width;
  final double height;
  final List<FurnitureSpot> spots;

  AutoCadLayout({
    required this.layoutId,
    required this.width,
    required this.height,
    required this.spots,
  });
}

class SeatMapBuilderScreen extends StatefulWidget {
  /// childType must be "Coffee" or "Restaurant"
  /// estateId is the ID under App/Estate/<childType>/<estateId>
  /// initialLayoutId, if non-null, will load an existing layout.
  final String childType;
  final String estateId;
  final String? initialLayoutId;

  const SeatMapBuilderScreen({
    super.key,
    required this.childType,
    required this.estateId,
    this.initialLayoutId,
  });

  @override
  State<SeatMapBuilderScreen> createState() => _SeatMapBuilderScreenState();
}

class _SeatMapBuilderScreenState extends State<SeatMapBuilderScreen> {
  late final String _layoutId;
  double? _roomWidth;
  double? _roomHeight;
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _spots = <FurnitureSpot>[];
  final uuid = const Uuid();

  FurnitureType _selectedType = FurnitureType.table;
  SeatType _selectedSeatType = SeatType.chair;
  DecorationType _selectedDecorationType = DecorationType.door;
  int _defaultCapacity = 4;
  TableShape _selectedShape = TableShape.rectangle;
  Color _selectedColor = Colors.brown;

  final Map<int, Size> _physicalTableSizes = {
    2: const Size(0.8, 0.6),
    4: const Size(1.2, 0.6),
    6: const Size(1.5, 0.8),
    8: const Size(1.8, 1.0),
  };

  @override
  void initState() {
    super.initState();
    _layoutId = widget.initialLayoutId ?? uuid.v4();
    if (widget.initialLayoutId != null) {
      _loadExistingLayout();
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  /// Load existing layout from Firebase.
  /// Prefills the width/height fields and loads spots, but
  /// does NOT set _roomWidth/_roomHeight so the dimension prompt still shows.
  Future<void> _loadExistingLayout() async {
    final ref = FirebaseDatabase.instance
        .ref('App')
        .child('Estate')
        .child(widget.childType)
        .child(widget.estateId)
        .child('AutoCad')
        .child(widget.initialLayoutId!);

    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final data = snapshot.value as Map<dynamic, dynamic>;
    final sizeMap = data['size'] as Map<dynamic, dynamic>;
    final w = (sizeMap['width'] as num).toDouble();
    final h = (sizeMap['height'] as num).toDouble();

    // Pre-fill controllers so user sees the old dims
    _widthController.text = w.toStringAsFixed(1);
    _heightController.text = h.toStringAsFixed(1);

    final spotsNode = data['spots'] as Map<dynamic, dynamic>;
    final loaded = <FurnitureSpot>[];
    spotsNode.forEach((key, value) {
      final m = value as Map<dynamic, dynamic>;
      loaded.add(FurnitureSpot(
        id: key as String,
        x: (m['x'] as num).toDouble(),
        y: (m['y'] as num).toDouble(),
        w: (m['w'] as num).toDouble(),
        h: (m['h'] as num).toDouble(),
        type: FurnitureType.values.firstWhere((e) => e.name == m['type']),
        capacity: m['capacity'] as int,
        shape: TableShape.values.firstWhere((e) => e.name == m['shape']),
        seatType: SeatType.values.firstWhere((e) => e.name == m['seatType']),
        decorationType: m['decoration'] != null
            ? DecorationType.values.firstWhere((e) => e.name == m['decoration'])
            : null,
        color: Color(m['color'] as int),
      ));
    });

    setState(() {
      _spots.clear();
      _spots.addAll(loaded);
    });
  }

  void _submitRoomSize() {
    final w = double.tryParse(_widthController.text);
    final h = double.tryParse(_heightController.text);
    if (w == null || h == null || w <= 0 || h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(getTranslated(context, 'Height & Width must be entered'))),
      );
      return;
    }
    setState(() {
      _roomWidth = w;
      _roomHeight = h;
    });
  }

  void _addSpot(Offset pos, Size canvas) {
    final xNorm = (pos.dx / canvas.width).clamp(0.0, 1.0);
    final yNorm = (pos.dy / canvas.height).clamp(0.0, 1.0);

    double wNorm, hNorm;
    switch (_selectedType) {
      case FurnitureType.table:
        final phys = _physicalTableSizes[_defaultCapacity]!;
        final baseW = phys.width / _roomWidth!;
        final baseH = phys.height / _roomHeight!;
        switch (_selectedShape) {
          case TableShape.square:
            final side = math.min(baseW, baseH);
            wNorm = hNorm = side;
            break;
          case TableShape.circle:
            wNorm = hNorm = (baseW + baseH) / 2;
            break;
          default:
            wNorm = baseW;
            hNorm = baseH;
        }
        wNorm = wNorm.clamp(0.03, 0.15);
        hNorm = hNorm.clamp(0.03, 0.15);
        break;
      case FurnitureType.seat:
        const seatSize = 0.5;
        wNorm = hNorm = (seatSize / _roomWidth!).clamp(0.03, 0.06);
        break;
      case FurnitureType.toilet:
        const toiletSize = 1.0;
        wNorm = (toiletSize / _roomWidth!).clamp(0.10, 0.15);
        hNorm = (toiletSize / _roomHeight!).clamp(0.10, 0.15);
        break;
      case FurnitureType.decoration:
        switch (_selectedDecorationType) {
          case DecorationType.window:
            wNorm = (1.2 / _roomWidth!).clamp(0.05, 0.20);
            hNorm = (1.0 / _roomHeight!).clamp(0.05, 0.20);
            break;
          case DecorationType.view:
            wNorm = (1.5 / _roomWidth!).clamp(0.05, 0.20);
            hNorm = (1.2 / _roomHeight!).clamp(0.05, 0.20);
            break;
          default:
            wNorm = (0.9 / _roomWidth!).clamp(0.05, 0.20);
            hNorm = (2.0 / _roomHeight!).clamp(0.05, 0.20);
        }
        break;
      case FurnitureType.bar:
        const barW = 2.0, barH = 0.6;
        wNorm = (barW / _roomWidth!).clamp(0.20, 0.50);
        hNorm = (barH / _roomHeight!).clamp(0.05, 0.15);
        break;
    }

    final spot = FurnitureSpot(
      id: uuid.v4().substring(0, 4),
      x: xNorm,
      y: yNorm,
      w: wNorm,
      h: hNorm,
      type: _selectedType,
      capacity: _selectedType == FurnitureType.table ? _defaultCapacity : 1,
      shape: _selectedType == FurnitureType.table
          ? _selectedShape
          : TableShape.rectangle,
      seatType: _selectedSeatType,
      decorationType: _selectedType == FurnitureType.decoration
          ? _selectedDecorationType
          : null,
      color: _selectedColor,
    );

    setState(() => _spots.add(spot));
  }

  Future<void> _pickDefaultColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(getTranslated(context, 'Pick default color')),
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
                        color: c, border: Border.all(color: Colors.black26))),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (color != null) setState(() => _selectedColor = color);
  }

  /// Overwrite the layout node in RTDB and return the layout to caller.
  // Future<void> _saveLayout() async {
  //   if (_spots.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content: Text(getTranslated(
  //               context, 'No spots added. Please add spots before saving.'))),
  //     );
  //     return;
  //   }
  //
  //   final ref = FirebaseDatabase.instance
  //       .ref('App')
  //       .child('Estate')
  //       .child(widget.childType)
  //       .child(widget.estateId)
  //       .child('AutoCad')
  //       .child(_layoutId);
  //
  //   final spotsMap = {
  //     for (var s in _spots)
  //       s.id: {
  //         'x': s.x,
  //         'y': s.y,
  //         'w': s.w,
  //         'h': s.h,
  //         'type': s.type.name,
  //         'capacity': s.capacity,
  //         'shape': s.shape.name,
  //         'seatType': s.seatType.name,
  //         'decoration': s.decorationType?.name,
  //         'color': s.color.value,
  //       }
  //   };
  //
  //   await ref.set({
  //     'size': {'width': _roomWidth, 'height': _roomHeight},
  //     'spots': spotsMap,
  //   });
  //
  //   Navigator.of(context).pop(AutoCadLayout(
  //     layoutId: _layoutId,
  //     width: _roomWidth!,
  //     height: _roomHeight!,
  //     spots: List.unmodifiable(_spots),
  //   ));
  // }

  Future<void> _saveLayout() async {
    if (_spots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(
              context, 'No spots added. Please add spots before saving.')),
        ),
      );
      return;
    }

    // 1️⃣ Write the AutoCad node
    final ref = FirebaseDatabase.instance
        .ref('App')
        .child('Estate')
        .child(widget.childType)
        .child(widget.estateId)
        .child('AutoCad')
        .child(_layoutId);

    final spotsMap = {
      for (var s in _spots)
        s.id: {
          'x': s.x,
          'y': s.y,
          'w': s.w,
          'h': s.h,
          'type': s.type.name,
          'capacity': s.capacity,
          'shape': s.shape.name,
          'seatType': s.seatType.name,
          'decoration': s.decorationType?.name,
          'color': s.color.value,
        }
    };

    await ref.set({
      'size': {'width': _roomWidth, 'height': _roomHeight},
      'spots': spotsMap,
    });

    // 2️⃣ Persist the LayoutId on the estate itself
    final estateRef = FirebaseDatabase.instance
        .ref('App')
        .child('Estate')
        .child(widget.childType)
        .child(widget.estateId);

    await estateRef.update({'LayoutId': _layoutId});

    // 3️⃣ Return the new layout to the caller
    Navigator.of(context).pop(AutoCadLayout(
      layoutId: _layoutId,
      width: _roomWidth!,
      height: _roomHeight!,
      spots: List.unmodifiable(_spots),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Always prompt for dimensions first:
    if (_roomWidth == null || _roomHeight == null) {
      return Scaffold(
        appBar: AppBar(title: Text(getTranslated(context, 'Enter Room Size'))),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextField(
              controller: _widthController,
              decoration: InputDecoration(
                labelText: getTranslated(context, 'Width (meters)'),
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: getTranslated(context, 'Height (meters)'),
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitRoomSize,
              child: Text(getTranslated(context, 'Start Building')),
            ),
          ]),
        ),
      );
    }

    // Then show the builder with loaded/new spots:
    return Scaffold(
      appBar: AppBar(
        title: Text(() {
          switch (_selectedType) {
            case FurnitureType.table:
              final shapeTranslated =
                  getTranslated(context, _selectedShape.name);
              return '$_defaultCapacity ${getTranslated(context, 'seat')} '
                  '$shapeTranslated ${getTranslated(context, 'table')}';
            case FurnitureType.seat:
              return getTranslated(context, _selectedSeatType.name);
            case FurnitureType.toilet:
              return getTranslated(context, 'toilet');
            case FurnitureType.decoration:
              return getTranslated(context, _selectedDecorationType.name);
            case FurnitureType.bar:
              return getTranslated(context, 'bar');
          }
        }()),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: getTranslated(context, 'Save Layout'),
            onPressed: _saveLayout,
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${getTranslated(context, "Room")}: '
            '${_roomWidth!.toStringAsFixed(1)} × ${_roomHeight!.toStringAsFixed(1)} m',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (ctx, box) {
            final canvas = Size(box.maxWidth, box.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (d) {
                final local = d.localPosition;
                final hit = _spots.any((s) {
                  final rawW = s.w * canvas.width;
                  final rawH = s.h * canvas.height;
                  final cw = s.type == FurnitureType.table
                      ? rawW
                      : math.min(rawW, rawH);
                  final ch = s.type == FurnitureType.table
                      ? rawH
                      : math.min(rawW, rawH);
                  final left = s.x * canvas.width - cw / 2;
                  final top = s.y * canvas.height - ch / 2;
                  return Rect.fromLTWH(left, top, cw, ch).contains(local);
                });
                if (!hit) _addSpot(local, canvas);
              },
              child: Stack(
                children: _spots
                    .map((spot) => SpotWidget(
                          spot: spot,
                          canvasSize: canvas,
                          onUpdate: () => setState(() {}),
                          onDelete: () => setState(() => _spots.remove(spot)),
                        ))
                    .toList(),
              ),
            );
          }),
        ),
        ToolBar(
          selectedType: _selectedType,
          selectedSeatType: _selectedSeatType,
          selectedDecorationType: _selectedDecorationType,
          selectedCapacity: _defaultCapacity,
          selectedShape: _selectedShape,
          selectedColor: _selectedColor,
          onTypeSelected: (t) => setState(() => _selectedType = t),
          onSeatTypeSelected: (st) => setState(() => _selectedSeatType = st),
          onDecorationTypeSelected: (dt) =>
              setState(() => _selectedDecorationType = dt),
          onCapacitySelected: (c) => setState(() => _defaultCapacity = c),
          onShapeSelected: (s) => setState(() => _selectedShape = s),
          onDefaultColorPick: _pickDefaultColor,
          onClear: () => setState(() => _spots.clear()),
        ),
      ]),
    );
  }
}
