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
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black,
                  letterSpacing: 0.15,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : Colors.black87,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilePersonalRow(label: 'Name', value: user.name),
          Divider(height: 1, color: isDark ? AppColors.divider : Colors.black),
          ProfilePersonalRow(label: 'Id', value: user.registrationNumber),
          Divider(height: 1, color: isDark ? AppColors.divider : Colors.black),
          ProfilePersonalRow(label: 'Programme', value: user.programme),
          Divider(height: 1, color: isDark ? AppColors.divider : Colors.black),
          ProfilePersonalRow(label: 'College', value: user.college),
          Divider(height: 1, color: isDark ? AppColors.divider : Colors.black),
          ProfilePersonalRow(label: 'E-mail', value: user.email),
          Divider(height: 1, color: isDark ? AppColors.divider : Colors.black),
          ProfilePersonalRow(label: 'Year', value: user.year),
        ],
      ),
    );
  }
}
