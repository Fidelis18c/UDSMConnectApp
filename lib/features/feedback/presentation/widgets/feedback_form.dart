import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/widgets/udsm_text_field.dart';
import '../../../../core/widgets/udsm_text_area.dart';
import '../../../../core/widgets/udsm_dropdown.dart';
import '../../../../core/widgets/udsm_button.dart';
import '../../data/repositories/feedback_repository.dart';

class FeedbackForm extends StatefulWidget {
  final List<FeedbackCategory> categories;
  final bool categoriesLoading;
  final bool submitting;
  final Future<void> Function(String subject, String categoryId, String description) onSubmit;

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

  Future<void> _handleSubmit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.length < 3 ||
        _selectedCategoryId == null ||
        message.isEmpty ||
        widget.submitting) {
      return;
    }

    await widget.onSubmit(subject, _selectedCategoryId!, message);

    if (!mounted) return;
    _subjectController.clear();
    _messageController.clear();
    setState(() => _selectedCategoryId = null);
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = widget.categories
        .map(
          (c) => DropdownMenuItem<String>(
            value: c.id,
            child: Text(c.name),
          ),
        )
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppShapes.cardBorderRadius,
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.categoriesLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                ),
              )
            else
              UdsmDropdown<String>(
                value: _selectedCategoryId,
                hint: 'Category',
                items: categoryItems,
                onChanged: widget.submitting
                    ? (_) {}
                    : (val) => setState(() => _selectedCategoryId = val),
              ),
            const SizedBox(height: 16),
            UdsmTextField(
              controller: _subjectController,
              hint: 'Subject',
            ),
            const SizedBox(height: 16),
            UdsmTextArea(
              controller: _messageController,
              hint: 'Describe your feedback or issue...',
              maxLines: 5,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_messageLength characters',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            UdsmButton(
              onPressed: widget.submitting || widget.categoriesLoading
                  ? null
                  : _handleSubmit,
              label: 'Send Feedback',
              isLoading: widget.submitting,
              prefixIcon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
