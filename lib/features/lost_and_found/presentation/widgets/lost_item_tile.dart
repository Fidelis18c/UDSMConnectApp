import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:udsm_connect/features/lost_and_found/data/models/lost_found.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';

class LostItemTile extends StatelessWidget {
  final LostFoundItem item;
  final VoidCallback onContact;

  const LostItemTile({
    Key? key,
    required this.item,
    required this.onContact,
  }) : super(key: key);

  Future<void> _makeCall(String? contact) async {
    if (contact == null || contact.isEmpty) return;
    
    // Clean the number
    final number = contact.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == 'LOST';
    final imageUrl = item.media.isNotEmpty ? item.media.first.url : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large Image Section - Only shown if imageUrl is present
          if (imageUrl != null)
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.grey[900],
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator.adaptive(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !isLost ? AppColors.statusReviewed : AppColors.statusPending,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      !isLost ? 'FOUND' : 'LOST',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (imageUrl == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: !isLost ? AppColors.statusReviewed : AppColors.statusPending,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          !isLost ? 'FOUND' : 'LOST',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location ?? 'Unknown location',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                
                // Contact Section (Compacted)
                if (item.contactInfo != null && item.contactInfo!.isNotEmpty)
                  InkWell(
                    onTap: () => _makeCall(item.contactInfo),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            item.contactInfo!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
