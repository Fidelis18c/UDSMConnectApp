import 'package:flutter/material.dart';
import 'package:udsm_connect/core/models/user_model.dart';

class ProfileDetailRow extends StatelessWidget {
  final String keyLabel;
  final String valueLabel;

  const ProfileDetailRow({
    Key? key,
    required this.keyLabel,
    required this.valueLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            keyLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          Text(
            valueLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final UserModel user;

  const ProfileInfoCard({
    Key? key,
    required this.user,
  }) : super(key: key);

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
          ProfileDetailRow(keyLabel: 'Reg Number', valueLabel: user.registrationNumber),
          const Divider(height: 16),
          ProfileDetailRow(keyLabel: 'College', valueLabel: user.college),
          const Divider(height: 16),
          ProfileDetailRow(keyLabel: 'Program', valueLabel: user.programme),
          const Divider(height: 16),
          ProfileDetailRow(keyLabel: 'Year', valueLabel: user.year),
          const Divider(height: 16),
          ProfileDetailRow(keyLabel: 'Email', valueLabel: user.email),
        ],
      ),
    );
  }
}
