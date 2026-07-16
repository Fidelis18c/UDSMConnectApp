import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';

class StoryBubble extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isViewed;
  final bool isAddStory;
  final VoidCallback onTap;

  StoryBubble({
    Key? key,
    required this.label,
    this.imageUrl,
    required this.isViewed,
    this.isAddStory = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAddStory)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: AppColors.divider, width: 1.2),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 22,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              )
            else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed
                    ? null
                    : const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.link,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                color: isViewed ? AppColors.divider : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.5), // Ring width
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor, // gap color
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0), // gap width
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                        image: isAddStory ? null : DecorationImage(
                          image: imageUrl != null && imageUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(imageUrl!)
                              : CachedNetworkImageProvider('https://ui-avatars.com/api/?name=${Uri.encodeComponent(label)}&background=random') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: isAddStory
                          ? const Center(
                              child: Icon(Icons.add, size: 32, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 74,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
