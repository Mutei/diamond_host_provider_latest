import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late final TransformationController _transformationController;

  // zoom state
  double _scale = 1.0;
  static const double _minScale = 1.0;
  static const double _maxScale = 3.0;
  static const double _step = 0.5;

  // swipe-to-dismiss state
  Offset _dragOffset = Offset.zero;
  double _backgroundOpacity = 1.0;
  static const double _dismissThreshold = 150.0;
  static const double _maxDragDistance = 300.0;

  final CacheManager _cacheManager = CacheManager(
    Config(
      'fullScreenCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200, // keep plenty of recent images
    ),
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();

    // 1) Prefetch to disk, 2) then precache into memory at screen resolution
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidthPx = (MediaQuery.of(context).size.width *
          MediaQuery.of(context).devicePixelRatio)
          .toInt();
      for (var url in widget.imageUrls) {
        _cacheManager.getSingleFile(url).then((file) {
          // once on disk, load into memory cache
          precacheImage(
            ResizeImage(FileImage(file), width: screenWidthPx),
            context,
          );
        }).catchError((e) {
          debugPrint('Error prefetching $url: $e');
        });
      }
    });
  }

  void _zoomToCenter(double targetScale) {
    final size = MediaQuery.of(context).size;
    final dx = (size.width * (1 - targetScale)) / 2;
    final dy = (size.height * (1 - targetScale)) / 2;

    setState(() {
      _scale = targetScale;
      _transformationController.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(targetScale);
    });
  }

  void _zoomIn() => _zoomToCenter((_scale + _step).clamp(_minScale, _maxScale));
  void _zoomOut() =>
      _zoomToCenter((_scale - _step).clamp(_minScale, _maxScale));

  void _onDoubleTap() {
    if (_scale == _minScale) {
      _zoomToCenter(_maxScale);
    } else {
      _zoomToCenter(_minScale);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // calculate memCacheWidth once per build
    final memCacheWidth = (MediaQuery.of(context).size.width *
        MediaQuery.of(context).devicePixelRatio)
        .toInt();

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(_backgroundOpacity),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (_scale == _minScale) {
            setState(() {
              _dragOffset += details.delta;
              _backgroundOpacity =
                  (1 - (_dragOffset.dy.abs() / _maxDragDistance))
                      .clamp(0.0, 1.0);
            });
          }
        },
        onVerticalDragEnd: (_) {
          if (_dragOffset.dy.abs() > _dismissThreshold) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _dragOffset = Offset.zero;
              _backgroundOpacity = 1.0;
            });
          }
        },
        child: Transform.translate(
          offset: _dragOffset,
          child: Stack(
            children: [
              GestureDetector(
                onDoubleTap: _onDoubleTap,
                child: Center(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: _minScale,
                        maxScale: _maxScale,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrls[index],
                          cacheManager: _cacheManager,
                          memCacheWidth: memCacheWidth,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade800,
                            highlightColor: Colors.grey.shade600,
                            child: Container(color: Colors.black),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // zoom buttons
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'zoom_in',
                      mini: true,
                      backgroundColor: Colors.black54,
                      onPressed: _zoomIn,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'zoom_out',
                      mini: true,
                      backgroundColor: Colors.black54,
                      onPressed: _zoomOut,
                      child: const Icon(Icons.remove, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
