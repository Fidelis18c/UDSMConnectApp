import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/theme/app_shapes.dart';
import 'package:udsm_connect/core/widgets/status_badge.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/features/feedback/data/repositories/feedback_repository.dart';
import 'package:udsm_connect/features/feedback/presentation/providers/feedback_provider.dart';
import '../widgets/feedback_form.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(
      String subject, String categoryId, String description) async {
    setState(() => _submitting = true);
    try {
      await ref.read(feedbackProvider.notifier).submit(
            subject: subject,
            description: description,
            categoryId: categoryId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
      );
      _tabController.animateTo(1);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit feedback. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(
              icon: PhosphorIcon(PhosphorIconsRegular.chatsTeardrop, size: 18),
              text: 'Send Feedback',
            ),
            Tab(
              icon: PhosphorIcon(PhosphorIconsRegular.clockCounterClockwise,
                  size: 18),
              text: 'My History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SendTab(submitting: _submitting, onSubmit: _handleSubmit),
          _HistoryTab(),
        ],
      ),
    );
  }
}

// ── Send Feedback tab ────────────────────────────────────────────────────────

class _SendTab extends ConsumerWidget {
  final bool submitting;
  final Future<void> Function(String subject, String categoryId,
      String description) onSubmit;

  const _SendTab({required this.submitting, required this.onSubmit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(feedbackCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We value your voice',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Directly reach out to DARUSO or the university administration to report issues or suggest improvements.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          categoriesAsync.when(
            loading: () => FeedbackForm(
              categories: const [],
              categoriesLoading: true,
              submitting: submitting,
              onSubmit: onSubmit,
            ),
            error: (_, __) => FeedbackForm(
              categories: const [],
              categoriesLoading: false,
              submitting: submitting,
              onSubmit: onSubmit,
            ),
            data: (categories) => FeedbackForm(
              categories: categories,
              categoriesLoading: false,
              submitting: submitting,
              onSubmit: onSubmit,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── My History tab ───────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackHistory = ref.watch(feedbackProvider);

    return RefreshIndicator.adaptive(
      onRefresh: () => ref.read(feedbackProvider.notifier).refresh(),
      child: feedbackHistory.when(
        loading: () => const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
          ),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyStateWidget(
                  icon: Icons.chat_outlined,
                  message: 'No feedback history yet',
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.divider,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _FeedbackHistoryTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _FeedbackHistoryTile extends StatelessWidget {
  final FeedbackItem item;

  const _FeedbackHistoryTile({required this.item});

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'REVIEWED':
        return Icons.mark_email_read_rounded;
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      case 'PENDING':
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REVIEWED':
        return AppColors.statusSubmitted;
      case 'RESOLVED':
        return AppColors.statusReviewed;
      case 'PENDING':
      default:
        return AppColors.statusPending;
    }
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _statusColor(item.status);

    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: AppShapes.cardBorderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppShapes.cardBorderRadius,
                ),
                child:
                    Icon(_statusIcon(item.status), color: iconColor, size: 22),
              ),
              title: Text(
                item.subject,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${item.category?.name ?? 'Uncategorized'} • ${_formatTimestamp(item.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(status: _mapStatus(item.status)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
            if (item.adminNote != null && item.adminNote!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(left: 64, right: 16, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.adminNote!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
}

// ── Feedback Detail Bottom Sheet ──────────────────────────────────────────────

class _FeedbackDetailSheet extends StatelessWidget {
  final FeedbackItem item;

  const _FeedbackDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final iconColor = _statusColorFor(item.status);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // Status icon + badge row
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: AppShapes.cardBorderRadius,
                          ),
                          child: Icon(_statusIconFor(item.status),
                              color: iconColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.subject,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Submitted ${_formatTimestamp(item.createdAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: _mapStatus(item.status)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category chip
                    if (item.category != null) ...[
                      _SectionLabel(label: 'Category'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          item.category!.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Message body
                    _SectionLabel(label: 'Your Message'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        item.description,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Admin response note
                    if (item.adminNote != null &&
                        item.adminNote!.isNotEmpty) ...[
                      _SectionLabel(label: 'Admin Response'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.adminNote!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _statusIconFor(String status) {
    switch (status.toUpperCase()) {
      case 'REVIEWED':
        return Icons.mark_email_read_rounded;
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color _statusColorFor(String status) {
    switch (status.toUpperCase()) {
      case 'REVIEWED':
        return AppColors.statusSubmitted;
      case 'RESOLVED':
        return AppColors.statusReviewed;
      default:
        return AppColors.statusPending;
    }
  }
}

// ── Small label widget ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

FeedbackStatus _mapStatus(String status) {
  switch (status.toUpperCase()) {
    case 'REVIEWED':
      return FeedbackStatus.reviewed;
    case 'RESOLVED':
      return FeedbackStatus.resolved;
    case 'PENDING':
    default:
      return FeedbackStatus.pending;
  }
}

String _formatTimestamp(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
