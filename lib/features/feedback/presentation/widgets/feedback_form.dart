import 'package:flutter/material.dart';
import '../../../../core/widgets/udsm_text_field.dart';
import '../../../../core/widgets/udsm_text_area.dart';
import '../../../../core/widgets/udsm_dropdown.dart';
import '../../../../core/widgets/udsm_button.dart';

class FeedbackForm extends StatefulWidget {
  final Function(String title, String category, String message) onSubmit;

  const FeedbackForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_titleController.text.trim().isEmpty || 
        _selectedCategory == null || 
        _messageController.text.trim().isEmpty) {
      return;
    }

    widget.onSubmit(
      _titleController.text.trim(),
      _selectedCategory!,
      _messageController.text.trim(),
    );

    // Clear form
    _titleController.clear();
    _messageController.clear();
    setState(() => _selectedCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UdsmDropdown<String>(
            value: _selectedCategory,
            hint: 'Category',
            items: const [
              DropdownMenuItem(value: 'Complaints', child: Text('Complaints')),
              DropdownMenuItem(value: 'Suggestion', child: Text('Suggestion')),
              DropdownMenuItem(value: 'Appreciation', child: Text('Appreciation')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          const SizedBox(height: 16),
          UdsmTextField(
            controller: _titleController,
            hint: 'Subject',
          ),
          const SizedBox(height: 16),
          UdsmTextArea(
            controller: _messageController,
            hint: 'Describe your feedback or issue...',
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          UdsmButton(
            onPressed: _handleSubmit,
            label: 'Submit Feedback',
          ),
        ],
      ),
    );
  }
}
