import 'package:flutter/material.dart';
import 'package:udsm_connect/core/models/user_model.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';

class ProfilePersonalRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfilePersonalRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.15,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
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
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilePersonalRow(label: 'Name', value: user.name),
          const Divider(height: 1, color: AppColors.divider),
          ProfilePersonalRow(label: 'Id', value: user.registrationNumber),
          const Divider(height: 1, color: AppColors.divider),
          ProfilePersonalRow(label: 'Programme', value: user.programme),
          const Divider(height: 1, color: AppColors.divider),
          ProfilePersonalRow(label: 'College', value: user.college),
          const Divider(height: 1, color: AppColors.divider),
          ProfilePersonalRow(label: 'E-mail', value: user.email),
          const Divider(height: 1, color: AppColors.divider),
          ProfilePersonalRow(label: 'Phone', value: user.phone),
          const Divider(height: 1, color: AppColors.divider),
          ProfilePersonalRow(label: 'Year', value: user.year),
        ],
      ),
    );
  }
}
