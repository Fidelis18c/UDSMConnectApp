import 'package:flutter/material.dart';

class ActionListCard extends StatelessWidget {
  final VoidCallback onChangePasswordLabel;
  final VoidCallback onChangeEmailLabel;

  const ActionListCard({
    Key? key,
    required this.onChangePasswordLabel,
    required this.onChangeEmailLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onChangePasswordLabel,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Change email'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onChangeEmailLabel,
          ),
        ],
      ),
    );
  }
}
