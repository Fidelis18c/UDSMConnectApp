import 'package:flutter/material.dart';
import '../../../../core/widgets/udsm_text_field.dart';
import '../../../../core/widgets/udsm_text_area.dart';

class ComposeFormFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final String? bodyHint;

  const ComposeFormFields({
    Key? key,
    required this.titleController,
    required this.bodyController,
    this.bodyHint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UdsmTextField(
          controller: titleController,
          hint: 'Title',
        ),
        const SizedBox(height: 16),
        UdsmTextArea(
          controller: bodyController,
          hint: bodyHint ?? 'Write your announcement here...',
          maxLines: 8,
        ),
      ],
    );
  }
}
