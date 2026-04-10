import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/status_badge.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/features/feedback/presentation/providers/feedback_provider.dart';
import 'package:udsm_connect/core/models/feedback_model.dart';
import '../widgets/feedback_form.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackHistory = ref.watch(feedbackProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We value your voice',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Directly reach out to DARUSO or the university administration to report issues or suggest improvements.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FeedbackForm(
                    onSubmit: (title, category, message) {
                      final newFeedback = FeedbackModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        category: category,
                        description: message,
                        timestamp: DateTime.now(),
                      );
                      ref.read(feedbackProvider.notifier).addFeedback(newFeedback);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feedback Submitted!')),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Your Feedback History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          feedbackHistory.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: EmptyStateWidget(
                      icon: Icons.chat_outlined,
                      message: 'No feedback history yet',
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = feedbackHistory[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StatusBadge(
                                  status: _mapStatus(item.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${item.category} • ${_formatTimestamp(item.timestamp)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: feedbackHistory.length,
                  ),
                ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
        ],
      ),
    );
  }

  // Local helper for status mapping (ensures type safety between feature and core)
  // In a real app we'd define this once in core/models
}

// Global helpers outside for simplicity within this file
dynamic _mapStatus(dynamic s) => s; // Simplified mapping layer

String _formatTimestamp(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

