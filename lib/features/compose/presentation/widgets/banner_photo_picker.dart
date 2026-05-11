import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class BannerPhotoPicker extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  final VoidCallback onTap;
  final VoidCallback onClear;

  const BannerPhotoPicker({
    Key? key,
    this.imageUrl,
    this.imageBytes,
    required this.onTap,
    required this.onClear,
  }) : super(key: key);

  bool get _hasPreview =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            style: BorderStyle.none,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Custom Dashed Border (Using custom painter or simple border if complex)
              CustomPaint(
                painter: DashedBorderPainter(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                child: Container(),
              ),
              
              if (imageBytes != null && imageBytes!.isNotEmpty)
                Positioned.fill(
                  child: Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                  ),
                )
              else if (imageUrl != null)
                Positioned.fill(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white24, size: 48),
                    ),
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Attach Poster',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to upload announcement image',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white38,
                            ),
                      ),
                    ],
                  ),
                ),

              if (_hasPreview)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
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

class DashedBorderPainter extends CustomPainter {
  final Color color;

  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8;
    const dashSpace = 4;
    double startY = 0;
    final path = Path();

    // Draw around the rect
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    
    // Simplification: use a basic dash pattern for the rect
    path.addRRect(rrect);

    // Using path_drawing for real dashes is better, but here we can iterate manually
    double currentDistance = 0;
    for (ui.PathMetric metric in path.computeMetrics()) {
      while (currentDistance < metric.length) {
        canvas.drawPath(
          metric.extractPath(currentDistance, currentDistance + dashWidth),
          paint,
        );
        currentDistance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
