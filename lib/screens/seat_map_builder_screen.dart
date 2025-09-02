// lib/screens/seat_map_builder_screen.dart

import 'dart:math' as math;
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/furniture_spot.dart';
import '../widgets/spot_widget.dart';
import '../widgets/tool_bar.dart';

/// Sides for overlays
enum OutdoorSide { north, south, east, west }

enum SecondFloorSide { north, south, east, west }

/// For internal selection tracking only
enum PlacementLayer { indoor, outdoor, secondFloor }

class AutoCadLayout {
  final String layoutId;
  final double width;
  final double height;

  // Outdoors
  final bool includeOutdoor;
  final List<OutdoorSide> outdoorSides;

  // Second floor
  final bool includeSecondFloor;
  final List<SecondFloorSide> secondFloorSides;

  // Separate spot lists per layer (room-normalized coordinates)
  final List<FurnitureSpot> spotsIndoor;
  final List<FurnitureSpot> spotsOutdoor;
  final List<FurnitureSpot> spotsSecond;

  AutoCadLayout({
    required this.layoutId,
    required this.width,
    required this.height,
    required this.includeOutdoor,
    required this.outdoorSides,
    required this.includeSecondFloor,
    required this.secondFloorSides,
    required this.spotsIndoor,
    required this.spotsOutdoor,
    required this.spotsSecond,
  });

  Map<String, dynamic> toJson() => {
        'layoutId': layoutId,
        'width': width,
        'height': height,
        'includeOutdoor': includeOutdoor,
        'outdoorSides': outdoorSides.map((s) => s.name).toList(),
        'includeSecondFloor': includeSecondFloor,
        'secondFloorSides': secondFloorSides.map((s) => s.name).toList(),
        'spots_indoor': spotsIndoor.map((e) => e.toJson()).toList(),
        'spots_outdoor': spotsOutdoor.map((e) => e.toJson()).toList(),
        'spots_second': spotsSecond.map((e) => e.toJson()).toList(),
      };

  factory AutoCadLayout.fromJson(Map<String, dynamic> json) {
    final includeOutdoor = json['includeOutdoor'] as bool? ?? false;
    final includeSecondFloor = json['includeSecondFloor'] as bool? ?? false;

    final outdoorSidesList = (json['outdoorSides'] as List<dynamic>?)
            ?.map((e) =>
                OutdoorSide.values.firstWhere((o) => o.name == (e as String)))
            .toList() ??
        <OutdoorSide>[];

    final secondFloorSidesList = (json['secondFloorSides'] as List<dynamic>?)
            ?.map((e) => SecondFloorSide.values
                .firstWhere((o) => o.name == (e as String)))
            .toList() ??
        <SecondFloorSide>[];

    // Back-compat: old single 'spots' becomes indoor.
    final List<FurnitureSpot> indoor = (json['spots_indoor'] as List?)
            ?.map((e) => FurnitureSpot.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList() ??
        (json['spots'] as List?)
            ?.map((e) => FurnitureSpot.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList() ??
        <FurnitureSpot>[];

    final List<FurnitureSpot> outdoor = (json['spots_outdoor'] as List?)
            ?.map((e) => FurnitureSpot.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList() ??
        <FurnitureSpot>[];

    final List<FurnitureSpot> second = (json['spots_second'] as List?)
            ?.map((e) => FurnitureSpot.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList() ??
        <FurnitureSpot>[];

    return AutoCadLayout(
      layoutId: json['layoutId'] as String,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      includeOutdoor: includeOutdoor,
      outdoorSides: outdoorSidesList,
      includeSecondFloor: includeSecondFloor,
      secondFloorSides: secondFloorSidesList,
      spotsIndoor: indoor,
      spotsOutdoor: outdoor,
      spotsSecond: second,
    );
  }
}

class SeatMapBuilderScreen extends StatefulWidget {
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

  // Outdoors (sides)
  bool _includeOutdoor = false;
  final Set<OutdoorSide> _outdoorSides = {};

  // Second floor (sides)
  bool _includeSecondFloor = false;
  final Set<SecondFloorSide> _secondFloorSides = {};

  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  // Spot lists per layer
  final _spotsIndoor = <FurnitureSpot>[];
  final _spotsOutdoor = <FurnitureSpot>[];
  final _spotsSecond = <FurnitureSpot>[];

  // Temp holders when loading existing layout (before sizing confirmed)
  final _loadedIndoor = <FurnitureSpot>[];
  final _loadedOutdoor = <FurnitureSpot>[];
  final _loadedSecond = <FurnitureSpot>[];

  // Selection: remember which layer the selected spot belongs to
  String? _selectedSpotId;
  PlacementLayer? _selectedLayer;

  final uuid = const Uuid();

  // Toolbar state
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

  // Safe translate
  String _tr(String key) => getTranslated(context, key) ?? key;

  @override
  void initState() {
    super.initState();
    _layoutId = widget.initialLayoutId ?? uuid.v4();
    if (widget.initialLayoutId != null) _loadExistingLayout();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickDefaultColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Pick default color')),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Colors.primaries.map((c) {
            return GestureDetector(
              onTap: () => Navigator.of(ctx).pop(c),
              child: Container(
                width: 30,
                height: 30,
                color: c,
                margin: const EdgeInsets.all(4),
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (color != null) setState(() => _selectedColor = color);
  }

  Future<void> _loadExistingLayout() async {
    final ref = FirebaseDatabase.instance.ref(
        'App/Estate/${widget.childType}/${widget.estateId}/AutoCad/$_layoutId');
    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final data = snapshot.value as Map<dynamic, dynamic>;

    // size
    if (data['size'] is Map) {
      final sizeMap = data['size'] as Map<dynamic, dynamic>;
      final w = (sizeMap['width'] as num).toDouble();
      final h = (sizeMap['height'] as num).toDouble();
      _widthController.text = w.toStringAsFixed(1);
      _heightController.text = h.toStringAsFixed(1);
    }

    // flags + sides
    final includeOut = data['includeOutdoor'] as bool? ?? false;
    final outSides = (data['outdoorSides'] as List<dynamic>?)
            ?.map((e) =>
                OutdoorSide.values.firstWhere((o) => o.name == (e as String)))
            .toSet() ??
        <OutdoorSide>{};

    final includeSecond = data['includeSecondFloor'] as bool? ?? false;
    final secondSides = (data['secondFloorSides'] as List<dynamic>?)
            ?.map((e) => SecondFloorSide.values
                .firstWhere((o) => o.name == (e as String)))
            .toSet() ??
        <SecondFloorSide>{};

    // spots (support new + legacy)
    final loadedIndoor = <FurnitureSpot>[];
    final loadedOutdoor = <FurnitureSpot>[];
    final loadedSecond = <FurnitureSpot>[];

    // legacy indoor node 'spots'
    if (data['spots'] is Map) {
      final node = data['spots'] as Map<dynamic, dynamic>;
      node.forEach((key, value) {
        final m = Map<String, dynamic>.from(value as Map);
        m['id'] = key as String;
        if (m.containsKey('decoration')) {
          m['decorationType'] = m['decoration'];
        }
        m.putIfAbsent('rotation', () => 0.0);
        loadedIndoor.add(FurnitureSpot.fromJson(m));
      });
    }

    // new nodes
    if (data['spots_indoor'] is Map) {
      final node = data['spots_indoor'] as Map<dynamic, dynamic>;
      node.forEach((key, value) {
        final m = Map<String, dynamic>.from(value as Map);
        m['id'] = key as String;
        m.putIfAbsent('rotation', () => 0.0);
        loadedIndoor.add(FurnitureSpot.fromJson(m));
      });
    }
    if (data['spots_outdoor'] is Map) {
      final node = data['spots_outdoor'] as Map<dynamic, dynamic>;
      node.forEach((key, value) {
        final m = Map<String, dynamic>.from(value as Map);
        m['id'] = key as String;
        m.putIfAbsent('rotation', () => 0.0);
        loadedOutdoor.add(FurnitureSpot.fromJson(m));
      });
    }
    if (data['spots_second'] is Map) {
      final node = data['spots_second'] as Map<dynamic, dynamic>;
      node.forEach((key, value) {
        final m = Map<String, dynamic>.from(value as Map);
        m['id'] = key as String;
        m.putIfAbsent('rotation', () => 0.0);
        loadedSecond.add(FurnitureSpot.fromJson(m));
      });
    }

    setState(() {
      _includeOutdoor = includeOut;
      _outdoorSides
        ..clear()
        ..addAll(outSides);

      _includeSecondFloor = includeSecond;
      _secondFloorSides
        ..clear()
        ..addAll(secondSides);

      _loadedIndoor
        ..clear()
        ..addAll(loadedIndoor);
      _loadedOutdoor
        ..clear()
        ..addAll(loadedOutdoor);
      _loadedSecond
        ..clear()
        ..addAll(loadedSecond);
    });
  }

  void _submitRoomSize() {
    final w = double.tryParse(_widthController.text);
    final h = double.tryParse(_heightController.text);
    if (w == null || h == null || w <= 0 || h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Height & Width must be entered'))),
      );
      return;
    }

    // VALIDATE: if a layer is enabled, it must have at least one side
    if (_includeOutdoor && _outdoorSides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Select at least one Outdoor side'))),
      );
      return;
    }
    if (_includeSecondFloor && _secondFloorSides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Select at least one Second Floor side'))),
      );
      return;
    }

    setState(() {
      _roomWidth = w;
      _roomHeight = h;

      _spotsIndoor
        ..clear()
        ..addAll(_loadedIndoor);
      _spotsOutdoor
        ..clear()
        ..addAll(_loadedOutdoor);
      _spotsSecond
        ..clear()
        ..addAll(_loadedSecond);

      _loadedIndoor.clear();
      _loadedOutdoor.clear();
      _loadedSecond.clear();
    });
  }

  Rect _calculateRoomRect(Size canvas) {
    if (_roomWidth == null || _roomHeight == null) {
      return Rect.fromLTWH(0, 0, canvas.width, canvas.height);
    }
    final roomRatio = _roomWidth! / _roomHeight!;
    final canvasRatio = canvas.width / canvas.height;
    double roomW, roomH;
    if (roomRatio > canvasRatio) {
      roomW = canvas.width * 0.95;
      roomH = roomW / roomRatio;
    } else {
      roomH = canvas.height * 0.85;
      roomW = roomH * roomRatio;
    }
    final left = (canvas.width - roomW) / 2;
    final top = (canvas.height - roomH) / 2;
    return Rect.fromLTWH(left, top, roomW, roomH);
  }

  /// ---------- Non-overlapping overlay helpers ----------
  /// If both layers choose the same side, we split the band 50/50:
  /// - Outdoor: the strip closest to the wall
  /// - Second Floor: the inner strip
  List<Rect> _outdoorRects(Rect roomRect) {
    final rects = <Rect>[];
    final bandW = roomRect.width * 0.20;
    final bandH = roomRect.height * 0.20;

    bool bothNorth = _outdoorSides.contains(OutdoorSide.north) &&
        _secondFloorSides.contains(SecondFloorSide.north);
    bool bothSouth = _outdoorSides.contains(OutdoorSide.south) &&
        _secondFloorSides.contains(SecondFloorSide.south);
    bool bothWest = _outdoorSides.contains(OutdoorSide.west) &&
        _secondFloorSides.contains(SecondFloorSide.west);
    bool bothEast = _outdoorSides.contains(OutdoorSide.east) &&
        _secondFloorSides.contains(SecondFloorSide.east);

    if (_outdoorSides.contains(OutdoorSide.north)) {
      final h = bothNorth ? bandH * 0.5 : bandH;
      rects.add(Rect.fromLTWH(roomRect.left, roomRect.top, roomRect.width, h));
    }
    if (_outdoorSides.contains(OutdoorSide.south)) {
      final h = bothSouth ? bandH * 0.5 : bandH;
      rects.add(
          Rect.fromLTWH(roomRect.left, roomRect.bottom - h, roomRect.width, h));
    }
    if (_outdoorSides.contains(OutdoorSide.west)) {
      final w = bothWest ? bandW * 0.5 : bandW;
      rects.add(Rect.fromLTWH(roomRect.left, roomRect.top, w, roomRect.height));
    }
    if (_outdoorSides.contains(OutdoorSide.east)) {
      final w = bothEast ? bandW * 0.5 : bandW;
      rects.add(
          Rect.fromLTWH(roomRect.right - w, roomRect.top, w, roomRect.height));
    }

    return rects;
  }

  List<Rect> _secondRects(Rect roomRect) {
    final rects = <Rect>[];
    final bandW = roomRect.width * 0.20;
    final bandH = roomRect.height * 0.20;

    bool bothNorth = _outdoorSides.contains(OutdoorSide.north) &&
        _secondFloorSides.contains(SecondFloorSide.north);
    bool bothSouth = _outdoorSides.contains(OutdoorSide.south) &&
        _secondFloorSides.contains(SecondFloorSide.south);
    bool bothWest = _outdoorSides.contains(OutdoorSide.west) &&
        _secondFloorSides.contains(SecondFloorSide.west);
    bool bothEast = _outdoorSides.contains(OutdoorSide.east) &&
        _secondFloorSides.contains(SecondFloorSide.east);

    if (_secondFloorSides.contains(SecondFloorSide.north)) {
      final h = bothNorth ? bandH * 0.5 : bandH;
      final top = bothNorth ? roomRect.top + bandH * 0.5 : roomRect.top;
      rects.add(Rect.fromLTWH(roomRect.left, top, roomRect.width, h));
    }
    if (_secondFloorSides.contains(SecondFloorSide.south)) {
      final h = bothSouth ? bandH * 0.5 : bandH;
      final top = bothSouth ? roomRect.bottom - bandH : roomRect.bottom - h;
      rects.add(Rect.fromLTWH(roomRect.left, top, roomRect.width, h));
    }
    if (_secondFloorSides.contains(SecondFloorSide.west)) {
      final w = bothWest ? bandW * 0.5 : bandW;
      final left = bothWest ? roomRect.left + bandW * 0.5 : roomRect.left;
      rects.add(Rect.fromLTWH(left, roomRect.top, w, roomRect.height));
    }
    if (_secondFloorSides.contains(SecondFloorSide.east)) {
      final w = bothEast ? bandW * 0.5 : bandW;
      final left = bothEast ? roomRect.right - bandW : roomRect.right - w;
      rects.add(Rect.fromLTWH(left, roomRect.top, w, roomRect.height));
    }

    return rects;
  }

  bool _pointInAnyRect(Offset p, List<Rect> rects) {
    for (final r in rects) {
      if (r.contains(p)) return true;
    }
    return false;
  }

  /// Determine which layer a tap belongs to using non-overlapping rects
  PlacementLayer _layerForTap(Offset pos, Rect roomRect) {
    final secondRects = _includeSecondFloor ? _secondRects(roomRect) : <Rect>[];
    if (_pointInAnyRect(pos, secondRects)) return PlacementLayer.secondFloor;

    final outdoorRects = _includeOutdoor ? _outdoorRects(roomRect) : <Rect>[];
    if (_pointInAnyRect(pos, outdoorRects)) return PlacementLayer.outdoor;

    if (roomRect.contains(pos)) return PlacementLayer.indoor;
    return PlacementLayer.indoor;
  }

  bool _isOverlapping(FurnitureSpot candidate, List<FurnitureSpot> list) {
    for (final s in list) {
      if (s.id == candidate.id) continue;
      final dx = (candidate.x - s.x).abs();
      final dy = (candidate.y - s.y).abs();
      final halfW = (candidate.w + s.w) / 2;
      final halfH = (candidate.h + s.h) / 2;
      if (dx < halfW && dy < halfH) return true;
    }
    return false;
  }

  List<FurnitureSpot> _spotsForLayer(PlacementLayer layer) {
    switch (layer) {
      case PlacementLayer.indoor:
        return _spotsIndoor;
      case PlacementLayer.outdoor:
        return _spotsOutdoor;
      case PlacementLayer.secondFloor:
        return _spotsSecond;
    }
  }

  // ---------- NEW: robust hit-test to select small items ----------
  Rect _spotAabb(FurnitureSpot s, Rect roomRect) {
    final cx = roomRect.left + s.x * roomRect.width;
    final cy = roomRect.top + s.y * roomRect.height;
    final w = s.w * roomRect.width;
    final h = s.h * roomRect.height;
    // Axis-aligned bounding box (works fine even when rotated a bit)
    return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
  }

  /// Returns the front-most spot hit at [pos] if any, with its layer.
  (PlacementLayer, FurnitureSpot)? _findSpotAt(Offset pos, Rect roomRect) {
    // Check order: second floor, outdoor, indoor (to mimic typical draw stacking)
    for (final list in [
      (PlacementLayer.secondFloor, _spotsSecond),
      (PlacementLayer.outdoor, _spotsOutdoor),
      (PlacementLayer.indoor, _spotsIndoor),
    ]) {
      final layer = list.$1;
      for (final s in list.$2.reversed) {
        // reversed = last drawn on top
        if (_spotAabb(s, roomRect).inflate(4).contains(pos)) {
          return (layer, s);
        }
      }
    }
    return null;
  }

  void _addSpotAt(Offset pos, Rect roomRect, PlacementLayer layer) {
    // Validate target layer sides if required
    if (layer == PlacementLayer.outdoor &&
        (!_includeOutdoor || _outdoorSides.isEmpty)) return;
    if (layer == PlacementLayer.secondFloor &&
        (!_includeSecondFloor || _secondFloorSides.isEmpty)) return;

    // Must tap inside allowed rects for that layer (non-overlapping)
    List<Rect> allowedRects;
    if (layer == PlacementLayer.indoor) {
      allowedRects = [roomRect];
    } else if (layer == PlacementLayer.outdoor) {
      allowedRects = _outdoorRects(roomRect);
    } else {
      allowedRects = _secondRects(roomRect);
    }
    if (!_pointInAnyRect(pos, allowedRects)) return;

    // Room-normalized coordinates (consistent for all layers)
    final xNorm = ((pos.dx - roomRect.left) / roomRect.width).clamp(0.0, 1.0);
    final yNorm = ((pos.dy - roomRect.top) / roomRect.height).clamp(0.0, 1.0);

    double wNorm, hNorm;
    switch (_selectedType) {
      case FurnitureType.table:
      case FurnitureType.bar:
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
          case TableShape.oval:
            wNorm = baseW * 1.2;
            hNorm = baseH * 0.8;
            break;
          case TableShape.rectangle:
          default:
            wNorm = baseW;
            hNorm = baseH;
        }
        wNorm = wNorm.clamp(0.03, 0.15);
        hNorm = hNorm.clamp(0.03, 0.15);
        break;
      case FurnitureType.seat:
        wNorm = hNorm = (0.5 / _roomWidth!).clamp(0.03, 0.06);
        break;
      case FurnitureType.toilet:
        wNorm = (1.0 / _roomWidth!).clamp(0.10, 0.15);
        hNorm = (1.0 / _roomHeight!).clamp(0.10, 0.15);
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

      /// NEW: Screen/TV (requires FurnitureType.screen in your model)
      case FurnitureType.screen:
        // Assume a wall-mounted TV panel ~1.6m x 0.1m (thin strip), clamped for small rooms
        wNorm = (1.6 / _roomWidth!).clamp(0.10, 0.30);
        hNorm = (0.10 / _roomHeight!).clamp(0.03, 0.08);
        break;
    }

    final newSpot = FurnitureSpot(
      id: uuid.v4().substring(0, 4),
      x: xNorm,
      y: yNorm,
      w: wNorm,
      h: hNorm,
      type: _selectedType,
      capacity: (_selectedType == FurnitureType.table ||
              _selectedType == FurnitureType.bar)
          ? _defaultCapacity
          : 1,
      shape: (_selectedType == FurnitureType.table ||
              _selectedType == FurnitureType.bar)
          ? _selectedShape
          : TableShape.rectangle,
      seatType: _selectedSeatType,
      decorationType: _selectedType == FurnitureType.decoration
          ? _selectedDecorationType
          : null,
      color: _selectedColor,
      rotation: 0.0,
    );

    final list = _spotsForLayer(layer);
    if (_isOverlapping(newSpot, list)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Cannot place on top of another item'))),
      );
      return;
    }

    setState(() {
      list.add(newSpot);
      _selectedSpotId = newSpot.id;
      _selectedLayer = layer;
    });
  }

  void _handleEditAction(String action) {
    if (_selectedSpotId == null || _selectedLayer == null) return;
    final list = _spotsForLayer(_selectedLayer!);
    final spot = list.firstWhere((s) => s.id == _selectedSpotId);

    setState(() {
      switch (action) {
        case 'increase':
          spot.w = (spot.w * 1.1).clamp(0.05, 1.0);
          spot.h = (spot.h * 1.1).clamp(0.05, 1.0);
          break;
        case 'decrease':
          spot.w = (spot.w * 0.9).clamp(0.05, 1.0);
          spot.h = (spot.h * 0.9).clamp(0.05, 1.0);
          break;
        case 'rotateLeft':
          spot.rotation = (spot.rotation - math.pi / 8) % (2 * math.pi);
          break;
        case 'rotateRight':
          spot.rotation = (spot.rotation + math.pi / 8) % (2 * math.pi);
          break;
        case 'color':
          _pickColorForSpot(spot);
          break;
        case 'duplicate':
          final clone = FurnitureSpot(
            id: uuid.v4().substring(0, 4),
            x: spot.x,
            y: spot.y,
            w: spot.w,
            h: spot.h,
            type: spot.type,
            capacity: spot.capacity,
            shape: spot.shape,
            seatType: spot.seatType,
            decorationType: spot.decorationType,
            color: spot.color,
            rotation: spot.rotation,
          );
          clone.x = (clone.x + 0.05).clamp(0.0, 1.0);
          clone.y = (clone.y + 0.05).clamp(0.0, 1.0);
          list.add(clone);
          _selectedSpotId = clone.id;
          break;
        case 'delete':
          list.removeWhere((s) => s.id == _selectedSpotId);
          _selectedSpotId = null;
          _selectedLayer = null;
          break;
      }
    });
  }

  Future<void> _pickColorForSpot(FurnitureSpot spot) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Change Color')),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Colors.primaries.map((c) {
            return GestureDetector(
              onTap: () => Navigator.of(ctx).pop(c),
              child: Container(
                width: 30,
                height: 30,
                color: c,
                margin: const EdgeInsets.all(4),
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (color != null) setState(() => spot.color = color);
  }

  bool _hasAnySpots() =>
      _spotsIndoor.isNotEmpty ||
      _spotsOutdoor.isNotEmpty ||
      _spotsSecond.isNotEmpty;

  void _clearAllSpots() {
    _spotsIndoor.clear();
    _spotsOutdoor.clear();
    _spotsSecond.clear();
    _selectedSpotId = null;
    _selectedLayer = null;
  }

  Future<void> _saveLayout() async {
    if (_roomWidth == null || _roomHeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Height & Width must be entered'))),
      );
      return;
    }
    // VALIDATE before saving: if layer is enabled, must have sides
    if (_includeOutdoor && _outdoorSides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Select at least one Outdoor side'))),
      );
      return;
    }
    if (_includeSecondFloor && _secondFloorSides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Select at least one Second Floor side'))),
      );
      return;
    }

    // Block saving if nothing was added
    if (!_hasAnySpots()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save: add items first')),
      );
      return;
    }

    final layout = AutoCadLayout(
      layoutId: _layoutId,
      width: _roomWidth!,
      height: _roomHeight!,
      includeOutdoor: _includeOutdoor,
      outdoorSides: _outdoorSides.toList(),
      includeSecondFloor: _includeSecondFloor,
      secondFloorSides: _secondFloorSides.toList(),
      spotsIndoor: List.unmodifiable(_spotsIndoor),
      spotsOutdoor: List.unmodifiable(_spotsOutdoor),
      spotsSecond: List.unmodifiable(_spotsSecond),
    );

    Navigator.of(context).pop(layout);
  }

  @override
  Widget build(BuildContext context) {
    if (_roomWidth == null || _roomHeight == null) {
      // Single-screen step for size + sides, then the canvas appears below.
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text(_tr('Enter Room Size'))),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _widthController,
                decoration: InputDecoration(
                  labelText: _tr('Width (meters)'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: _tr('Height (meters)'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // OUTDOOR
              SwitchListTile(
                title: Text(_tr('Include Outdoor Seating')),
                value: _includeOutdoor,
                onChanged: (v) => setState(() => _includeOutdoor = v),
              ),
              if (_includeOutdoor) ...[
                const SizedBox(height: 8),
                Text(
                  _tr('Select outdoor wall(s):'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                for (var side in OutdoorSide.values)
                  CheckboxListTile(
                    title: Text(_tr(side.name)),
                    value: _outdoorSides.contains(side),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _outdoorSides.add(side);
                        } else {
                          _outdoorSides.remove(side);
                        }
                      });
                    },
                  ),
              ],

              const Divider(height: 32),

              // SECOND FLOOR
              SwitchListTile(
                title: Text(_tr('Include Second Floor')),
                value: _includeSecondFloor,
                onChanged: (v) => setState(() => _includeSecondFloor = v),
              ),
              if (_includeSecondFloor) ...[
                const SizedBox(height: 8),
                Text(
                  _tr('Select second floor wall(s):'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                for (var side in SecondFloorSide.values)
                  CheckboxListTile(
                    title: Text(_tr(side.name)),
                    value: _secondFloorSides.contains(side),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _secondFloorSides.add(side);
                        } else {
                          _secondFloorSides.remove(side);
                        }
                      });
                    },
                  ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitRoomSize,
                child: Text(_tr('Start Building')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(() {
          switch (_selectedType) {
            case FurnitureType.table:
            case FurnitureType.bar:
              final shape = _tr(_selectedShape.name);
              final kind =
                  _selectedType == FurnitureType.table ? 'table' : 'bar';
              return '$_defaultCapacity ${_tr('seat')} $shape ${_tr(kind)}';
            case FurnitureType.seat:
              return _tr(_selectedSeatType.name);
            case FurnitureType.toilet:
              return _tr('toilet');
            case FurnitureType.decoration:
              return _tr(_selectedDecorationType.name);
            case FurnitureType.screen:
              return _tr('screen');
          }
          // switch (_selectedType) {
          //   case FurnitureType.table:
          //   case FurnitureType.bar:
          //     final shape = _tr(_selectedShape.name);
          //     final kind =
          //     _selectedType == FurnitureType.table ? 'table' : 'bar';
          //     return '$_defaultCapacity ${_tr('seat')} $shape ${_tr(kind)}';
          //   case FurnitureType.seat:
          //     return _tr(_selectedSeatType.name);
          //   case FurnitureType.toilet:
          //     return _tr('toilet');
          //   case FurnitureType.decoration:
          //     return _tr(_selectedDecorationType.name);
          // }
        }()),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: _tr('Save Layout'),
            onPressed: _saveLayout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              '${_tr("Room")}: '
              '${_roomWidth!.toStringAsFixed(1)} × '
              '${_roomHeight!.toStringAsFixed(1)} m',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          // Small legend for overlays
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _legendChip(color: Colors.black26, label: _tr('Indoor')),
                if (_includeOutdoor)
                  _legendChip(
                    color: Colors.lightGreen.withOpacity(0.5),
                    label: _tr('Outdoor'),
                  ),
                if (_includeSecondFloor)
                  _legendChip(
                    color: Colors.indigo.withOpacity(0.45),
                    label: _tr('Second Floor'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ---------- IMPORTANT: GestureDetector moved to wrap ONLY the canvas ----------
          Expanded(
            child: LayoutBuilder(builder: (ctx, box) {
              final canvas = Size(box.maxWidth, box.maxHeight);
              final roomRect = _calculateRoomRect(canvas);

              // Non-overlapping overlay rects
              final outdoorRects =
                  _includeOutdoor ? _outdoorRects(roomRect) : <Rect>[];
              final secondRects =
                  _includeSecondFloor ? _secondRects(roomRect) : <Rect>[];

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final local = details.localPosition;

                  // If tap hits an existing spot, select it and DO NOT add new.
                  final hit = _findSpotAt(local, roomRect);
                  if (hit != null) {
                    setState(() {
                      _selectedLayer = hit.$1;
                      _selectedSpotId = hit.$2.id;
                    });
                    return;
                  }

                  // Only add when tap is inside the room/overlays region;
                  // taps on the legend/empty areas won't add anything.
                  if (!roomRect.contains(local) &&
                      !_pointInAnyRect(local, outdoorRects) &&
                      !_pointInAnyRect(local, secondRects)) {
                    return;
                  }

                  final layer = _layerForTap(local, roomRect);
                  _addSpotAt(local, roomRect, layer);
                },
                child: Stack(
                  children: [
                    // dim outside room
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RoomBoundaryPainter(roomRect),
                      ),
                    ),

                    // OUTDOOR overlays (green)
                    for (final r in outdoorRects)
                      Positioned.fromRect(
                        rect: r,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.lightGreen.withOpacity(0.30),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.6), width: 1),
                          ),
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _tr('Outdoor'),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green),
                          ),
                        ),
                      ),

                    // SECOND-FLOOR overlays (indigo)
                    for (final r in secondRects)
                      Positioned.fromRect(
                        rect: r,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.25),
                            border: Border.all(
                                color: Colors.indigo.withOpacity(0.8),
                                width: 1),
                          ),
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _tr('Second Floor'),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo),
                          ),
                        ),
                      ),

                    // INDOOR spots (rendered on room)
                    ..._spotsIndoor.map((spot) => SpotWidget(
                          spot: spot,
                          allSpots: _spotsIndoor,
                          canvasSize: roomRect.size,
                          offset: Offset(roomRect.left, roomRect.top),
                          isSelected: _selectedSpotId == spot.id &&
                              _selectedLayer == PlacementLayer.indoor,
                          onSelect: () => setState(() {
                            _selectedSpotId = spot.id;
                            _selectedLayer = PlacementLayer.indoor;
                          }),
                          onUpdate: () => setState(() {}),
                          onDelete: () {
                            setState(() {
                              _spotsIndoor.remove(spot);
                              if (_selectedSpotId == spot.id) {
                                _selectedSpotId = null;
                                _selectedLayer = null;
                              }
                            });
                          },
                        )),

                    // OUTDOOR spots
                    ..._spotsOutdoor.map((spot) => SpotWidget(
                          spot: spot,
                          allSpots: _spotsOutdoor,
                          canvasSize: roomRect.size,
                          offset: Offset(roomRect.left, roomRect.top),
                          isSelected: _selectedSpotId == spot.id &&
                              _selectedLayer == PlacementLayer.outdoor,
                          onSelect: () => setState(() {
                            _selectedSpotId = spot.id;
                            _selectedLayer = PlacementLayer.outdoor;
                          }),
                          onUpdate: () => setState(() {}),
                          onDelete: () {
                            setState(() {
                              _spotsOutdoor.remove(spot);
                              if (_selectedSpotId == spot.id) {
                                _selectedSpotId = null;
                                _selectedLayer = null;
                              }
                            });
                          },
                        )),

                    // SECOND-FLOOR spots
                    ..._spotsSecond.map((spot) => SpotWidget(
                          spot: spot,
                          allSpots: _spotsSecond,
                          canvasSize: roomRect.size,
                          offset: Offset(roomRect.left, roomRect.top),
                          isSelected: _selectedSpotId == spot.id &&
                              _selectedLayer == PlacementLayer.secondFloor,
                          onSelect: () => setState(() {
                            _selectedSpotId = spot.id;
                            _selectedLayer = PlacementLayer.secondFloor;
                          }),
                          onUpdate: () => setState(() {}),
                          onDelete: () {
                            setState(() {
                              _spotsSecond.remove(spot);
                              if (_selectedSpotId == spot.id) {
                                _selectedSpotId = null;
                                _selectedLayer = null;
                              }
                            });
                          },
                        )),

                    // room border
                    Positioned(
                      left: roomRect.left,
                      top: roomRect.top,
                      width: roomRect.width,
                      height: roomRect.height,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.teal, width: 3),
                          ),
                        ),
                      ),
                    ),

                    if (_selectedSpotId != null && _selectedLayer != null)
                      _buildFloatingEditBar(context, roomRect),
                  ],
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

            // Clear dialog with "All layers (remove everything)"
            onClear: () async {
              final choice = await showDialog<String?>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(_tr('Clear which layer?')),
                  children: [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'indoor'),
                      child: Text(_tr('Indoor')),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'outdoor'),
                      child: Text(_tr('Outdoor')),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'second'),
                      child: Text(_tr('Second Floor')),
                    ),
                    const Divider(),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'all'),
                      child: const Text('All layers (remove everything)'),
                    ),
                    const Divider(),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: Text(_tr('Cancel')),
                    ),
                  ],
                ),
              );

              if (choice == null) return;
              setState(() {
                switch (choice) {
                  case 'indoor':
                    _spotsIndoor.clear();
                    break;
                  case 'outdoor':
                    _spotsOutdoor.clear();
                    break;
                  case 'second':
                    _spotsSecond.clear();
                    break;
                  case 'all':
                    _clearAllSpots();
                    break;
                }
                _selectedSpotId = null;
                _selectedLayer = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _legendChip({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFloatingEditBar(BuildContext context, Rect roomRect) {
    final list = _selectedLayer == null
        ? <FurnitureSpot>[]
        : _spotsForLayer(_selectedLayer!);
    if (_selectedSpotId == null || _selectedLayer == null) {
      return const SizedBox.shrink();
    }
    final spot = list.firstWhere((s) => s.id == _selectedSpotId);
    const barW = 340.0, barH = 50.0;

    final topPx = roomRect.top + spot.y * roomRect.height;
    final leftPx = roomRect.left + spot.x * roomRect.width;
    final leftMin = roomRect.left;
    final leftMax = math.max(roomRect.right - barW, leftMin);
    final topMin = roomRect.top;
    final topMax = math.max(roomRect.bottom - barH, topMin);
    final clampedLeft = (leftPx + 80).clamp(leftMin, leftMax);
    final clampedTop = (topPx - 50).clamp(topMin, topMax);

    return Positioned(
      left: clampedLeft,
      top: clampedTop,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _circleButton(Icons.close, 'Close', () {
            setState(() {
              _selectedSpotId = null;
              _selectedLayer = null;
            });
          }, background: Colors.grey.shade200),
          const SizedBox(width: 6),
          _circleButton(Icons.add, 'Increase', () {
            _handleEditAction('increase');
          }),
          const SizedBox(width: 6),
          _circleButton(Icons.remove, 'Decrease', () {
            _handleEditAction('decrease');
          }),
          const SizedBox(width: 6),
          _circleButton(Icons.rotate_left, 'Rotate Left', () {
            _handleEditAction('rotateLeft');
          }),
          const SizedBox(width: 6),
          _circleButton(Icons.rotate_right, 'Rotate Right', () {
            _handleEditAction('rotateRight');
          }),
          const SizedBox(width: 6),
          _circleButton(Icons.color_lens, 'Color', () {
            _handleEditAction('color');
          }),
          const SizedBox(width: 6),
          _circleButton(Icons.copy, 'Duplicate', () {
            _handleEditAction('duplicate');
          }),
          const SizedBox(width: 6),
          _circleButton(Icons.delete, 'Delete', () {
            _handleEditAction('delete');
          }, background: Colors.red.shade100, iconColor: Colors.red),
        ]),
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    Color background = const Color(0xFFF0F0F0),
    Color iconColor = Colors.black87,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

class _RoomBoundaryPainter extends CustomPainter {
  final Rect roomRect;
  _RoomBoundaryPainter(this.roomRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, roomRect.top), paint);
    canvas.drawRect(
        Rect.fromLTWH(
            0, roomRect.bottom, size.width, size.height - roomRect.bottom),
        paint);
    canvas.drawRect(
        Rect.fromLTWH(0, roomRect.top, roomRect.left, roomRect.height), paint);
    canvas.drawRect(
        Rect.fromLTWH(roomRect.right, roomRect.top, size.width - roomRect.right,
            roomRect.height),
        paint);
  }

  @override
  bool shouldRepaint(covariant _RoomBoundaryPainter old) =>
      old.roomRect != roomRect;
}
