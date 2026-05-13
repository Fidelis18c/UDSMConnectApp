import 'package:flutter/material.dart';
import 'package:udsm_connect/features/lost_and_found/data/models/lost_found.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/widgets/contact_button.dart';

class LostItemTile extends StatelessWidget {
  final LostFoundItem item;
  final VoidCallback onContact;

  const LostItemTile({
    Key? key,
    required this.item,
    required this.onContact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == 'LOST';
    final imageUrl = item.media.isNotEmpty ? item.media.first.url : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: AppShapes.imageAssetBorderRadius,
              image: imageUrl != null 
                ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                : null,
            ),
            child: imageUrl == null ? const Icon(Icons.image, color: Colors.white54) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: !isLost ? AppColors.statusReviewed : AppColors.statusPending,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        !isLost ? 'FOUND' : 'LOST',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.location ?? 'No location provided',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ContactButton(onTap: onContact),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
