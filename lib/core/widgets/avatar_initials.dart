import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarInitials extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final bool showCameraIcon;

  const AvatarInitials({
    Key? key,
    required this.initials,
    this.imageUrl,
    this.radius = 24.0,
    this.backgroundColor,
    this.showCameraIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final textColor = Colors.white;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          backgroundImage:
              hasImage ? CachedNetworkImageProvider(imageUrl!) : null,
          child: !hasImage
              ? Text(
                  initials.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: radius * 0.8,
                      ),
                )
              : null,
        ),
        if (showCameraIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
