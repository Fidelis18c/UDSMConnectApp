import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';

class BannerPhotoPicker extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  final VoidCallback onTap;
  final VoidCallback onClear;

  BannerPhotoPicker({
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
          border: Border.all(color: AppColors.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (imageBytes != null && imageBytes!.isNotEmpty)
                Positioned.fill(
                  child: Image.memory(imageBytes!, fit: BoxFit.cover),
                )
              else if (imageUrl != null)
                Positioned.fill(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white24, size: 48),
                    ),
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 40,
                    color: Colors.white,
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
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.white),
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
