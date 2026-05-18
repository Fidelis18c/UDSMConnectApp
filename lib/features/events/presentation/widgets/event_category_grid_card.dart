import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/event.dart';
import '../../../../core/theme/app_colors.dart';

class EventCategoryGridCard extends StatelessWidget {
  final EventCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const EventCategoryGridCard({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _categoryColor(category.name).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    _categoryIcon(category.name),
                    color: _categoryColor(category.name),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Category name
              Expanded(
                child: Text(
                  category.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFFCCCCCC),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'music':
        return Icons.music_note_rounded;
      case 'comedy':
        return Icons.sentiment_very_satisfied_rounded;
      case 'spirituality':
        return Icons.self_improvement_rounded;
      case 'sports':
      case 'sport':
        return Icons.sports_soccer_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'technology':
      case 'tech':
        return Icons.computer_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'arts':
      case 'art':
        return Icons.palette_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'networking':
        return Icons.people_rounded;
      case 'conference':
        return Icons.mic_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _categoryColor(String name) {
    switch (name.toLowerCase()) {
      case 'music':
        return const Color(0xFF9C27B0);
      case 'comedy':
        return const Color(0xFFFF9800);
      case 'spirituality':
        return const Color(0xFF26A69A);
      case 'sports':
      case 'sport':
        return const Color(0xFF4CAF50);
      case 'education':
        return const Color(0xFF2196F3);
      case 'business':
        return const Color(0xFF607D8B);
      case 'technology':
      case 'tech':
        return const Color(0xFF00BCD4);
      case 'health':
        return const Color(0xFFF44336);
      case 'arts':
      case 'art':
        return const Color(0xFFE91E63);
      case 'food':
        return const Color(0xFFFF5722);
      case 'networking':
        return const Color(0xFF3F51B5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
