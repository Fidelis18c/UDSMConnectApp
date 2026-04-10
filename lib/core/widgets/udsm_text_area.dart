import 'package:flutter/material.dart';

class UdsmTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const UdsmTextArea({
    Key? key,
    required this.controller,
    required this.hint,
    this.maxLines = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: Theme.of(context).primaryColor,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        alignLabelWithHint: true,
      ),
    );
  }
}
