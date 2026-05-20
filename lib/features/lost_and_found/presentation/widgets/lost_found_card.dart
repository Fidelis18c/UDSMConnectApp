import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/lost_found.dart';
import '../../../../core/theme/app_colors.dart';

const _lostColor = AppColors.primary;             // blue
const _foundColor = Color(0xFF2E7D32);             // green = AppColors.statusReviewed

class LostFoundCard extends StatelessWidget {
  final LostFoundItem item;
  final VoidCallback onTap;

  const LostFoundCard({super.key, required this.item, required this.onTap});

  bool get _isLost => item.type == 'LOST';
  bool get _isResolved => item.status == 'RESOLVED';

  @override
  Widget build(BuildContext context) {
    final badgeColor = _isResolved
        ? const Color(0xFFD32F2F)
        : (_isLost ? _lostColor : _foundColor);
    final badgeText = _isResolved ? 'RESOLVED' : (_isLost ? 'LOST' : 'FOUND');
    final imageUrl = item.displayImageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(102),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image + badge ────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),

                  // LOST / FOUND / RESOLVED badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  if (_isResolved)
                    Container(
                      color: Colors.black.withAlpha(120),
                    ),
                ],
              ),
            ),

            // ── Text info ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title UPPERCASE, primary color
                  Text(
                    item.title.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _isLost ? _lostColor : _foundColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (item.location != null && item.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.location!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 4),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'Posted by '),
                        TextSpan(
                          text: item.reporter?.fullName ?? 'Anonymous',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            size: 40, color: Color(0xFF444444)),
      ),
    );
  }
}
