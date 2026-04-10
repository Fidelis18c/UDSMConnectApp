import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarInitials extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final bool showCameraIcon;

  const AvatarInitials({
    Key? key,
    required this.initials,
    this.imageUrl,
    this.radius = 24.0,
    this.backgroundColor = AppColors.surface,
    this.showCameraIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  initials.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
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
