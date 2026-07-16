import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/feedback_repository.dart';

/// Maps known feedback category names to icons (display only).
IconData categoryIconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('academic') || n.contains('class') || n.contains('exam')) {
    return PhosphorIconsRegular.graduationCap;
  }
  if (n.contains('hostel') || n.contains('accommodation') || n.contains('housing')) {
    return PhosphorIconsRegular.buildings;
  }
  if (n.contains('health') || n.contains('clinic') || n.contains('medical')) {
    return PhosphorIconsRegular.heartbeat;
  }
  if (n.contains('finance') || n.contains('fee') || n.contains('payment')) {
    return PhosphorIconsRegular.wallet;
  }
  if (n.contains('sport') || n.contains('game')) {
    return PhosphorIconsRegular.soccerBall;
  }
  if (n.contains('security') || n.contains('safety')) {
    return PhosphorIconsRegular.shieldCheck;
  }
  if (n.contains('suggest') || n.contains('idea') || n.contains('improve')) {
    return PhosphorIconsRegular.lightbulb;
  }
  if (n.contains('complaint') || n.contains('issue') || n.contains('report')) {
    return PhosphorIconsRegular.warningCircle;
  }
  if (n.contains('it') || n.contains('system') || n.contains('app') || n.contains('tech')) {
    return PhosphorIconsRegular.desktop;
  }
  return PhosphorIconsRegular.chatCircleDots;
}

class FeedbackForm extends StatefulWidget {
  final List<FeedbackCategory> categories;
  final bool categoriesLoading;
  final bool submitting;
  final Future<void> Function(
    String subject,
    String categoryId,
    String description,
  ) onSubmit;

  const FeedbackForm({
    super.key,
    required this.categories,
    required this.categoriesLoading,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedCategoryId;
  int _messageLength = 0;
  static const _maxMessage = 1000;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() => _messageLength = _messageController.text.length);
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    return subject.length >= 3 &&
        _selectedCategoryId != null &&
        message.isNotEmpty &&
        !widget.submitting &&
        !widget.categoriesLoading;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedCategoryId == null
                ? 'Pick a category first'
                : _subjectController.text.trim().length < 3
                    ? 'Subject needs at least 3 characters'
                    : 'Please write a short message',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await widget.onSubmit(
      _subjectController.text.trim(),
      _selectedCategoryId!,
      _messageController.text.trim(),
    );

    if (!mounted) return;
    _subjectController.clear();
    _messageController.clear();
    setState(() => _selectedCategoryId = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category chips
        Text(
          'Category',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 10),
        if (widget.categoriesLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
            ),
          )
        else if (widget.categories.isEmpty)
          Text(
            'No categories available right now.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textHint),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((c) {
              final selected = _selectedCategoryId == c.id;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.submitting
                      ? null
                      : () => setState(() => _selectedCategoryId = c.id),
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIconFor(c.name),
                          size: 16,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          c.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        SizedBox(height: 22),

        // Subject
        Text(
          'Subject',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _subjectController,
          enabled: !widget.submitting,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          style: theme.textTheme.bodyMedium,
          decoration: _inputDecoration(
            context,
            hint: 'Short title for your feedback',
            icon: PhosphorIconsRegular.notePencil,
          ),
        ),

        SizedBox(height: 18),

        // Message
        Text(
          'Details',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _messageController,
          enabled: !widget.submitting,
          maxLines: 5,
          maxLength: _maxMessage,
          onChanged: (_) => setState(() {}),
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          decoration: _inputDecoration(
            context,
            hint: 'Describe the issue or idea clearly…',
            icon: null,
          ).copyWith(
            counterText: '',
            contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          ),
        ),
        SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_messageLength / $_maxMessage',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _messageLength > _maxMessage * 0.9
                  ? AppColors.statusPending
                  : AppColors.textHint,
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Submit
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _canSubmit ? _handleSubmit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: widget.submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Send feedback',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    IconData? icon,
  }) {
    final fill = Theme.of(context).colorScheme.surface;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
      filled: true,
      fillColor: fill,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: AppColors.textSecondary)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
    );
  }
}
