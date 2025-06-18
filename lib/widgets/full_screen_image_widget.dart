import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';
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
  int _currentIndex = 0;

  // swipe-to-dismiss state
  Offset _dragOffset = Offset.zero;
  double _backgroundOpacity = 1.0;
  static const double _dismissThreshold = 150.0;
  static const double _maxDragDistance = 300.0;

  final CacheManager _cacheManager = CacheManager(
    Config(
      'fullScreenCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // 1) Prefetch to disk, 2) then precache into memory at screen resolution
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidthPx = (MediaQuery.of(context).size.width *
              MediaQuery.of(context).devicePixelRatio)
          .toInt();
      for (var url in widget.imageUrls) {
        _cacheManager.getSingleFile(url).then((file) {
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // dim background based on drag
      backgroundColor: Colors.black.withOpacity(_backgroundOpacity),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta;
            _backgroundOpacity =
                (1 - (_dragOffset.dy.abs() / _maxDragDistance)).clamp(0.0, 1.0);
          });
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
              // PhotoView gallery
              PhotoViewGallery.builder(
                pageController: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: widget.imageUrls.length,
                builder: (ctx, index) {
                  final url = widget.imageUrls[index];
                  return PhotoViewGalleryPageOptions(
                    imageProvider: CachedNetworkImageProvider(url,
                        cacheManager: _cacheManager),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    initialScale: PhotoViewComputedScale.contained,
                    heroAttributes: PhotoViewHeroAttributes(tag: url),
                    errorBuilder: (context, error, stack) => Center(
                      child: Icon(Icons.error, color: Colors.white, size: 48),
                    ),
                  );
                },
                loadingBuilder: (context, event) => Center(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade800,
                    highlightColor: Colors.grey.shade600,
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.black,
                    ),
                  ),
                ),
                backgroundDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(_backgroundOpacity)),
              ),

              // top bar with close button and page indicator
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Spacer(),
                    Text(
                      '${_currentIndex + 1}/${widget.imageUrls.length}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ),

              // bottom dots indicator
              if (widget.imageUrls.length > 1)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.imageUrls.length,
                      (i) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == i ? 12 : 8,
                        height: _currentIndex == i ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == i
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
