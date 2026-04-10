import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';

enum FeedbackStatus { pending, reviewed, submitted }

class StatusBadge extends StatelessWidget {
  final FeedbackStatus status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  String _getLabel() {
    switch (status) {
      case FeedbackStatus.pending: return 'Pending';
      case FeedbackStatus.reviewed: return 'Reviewed';
      case FeedbackStatus.submitted: return 'Submitted';
    }
  }

  Color _getColor() {
    switch (status) {
      case FeedbackStatus.pending: return AppColors.statusPending;
      case FeedbackStatus.reviewed: return AppColors.statusReviewed;
      case FeedbackStatus.submitted: return AppColors.statusSubmitted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.15),
        borderRadius: AppShapes.pillBorderRadius,
        border: Border.all(color: _getColor(), width: 1.5),
      ),
      child: Text(
        _getLabel(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getColor(),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
