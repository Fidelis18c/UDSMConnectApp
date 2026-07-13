import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Opens [url] full-screen on a black background with pinch-to-zoom.
/// Tapping anywhere (or the close button) dismisses it.
void openFullScreenImage(BuildContext context, String url) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => FullScreenImageViewer(url: url),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class FullScreenImageViewer extends StatelessWidget {
  final String url;

  const FullScreenImageViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  fadeInDuration: Duration.zero,
                  progressIndicatorBuilder: (_, __, progress) => Center(
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      value: progress.progress,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
