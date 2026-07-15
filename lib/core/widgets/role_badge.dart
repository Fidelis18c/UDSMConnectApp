import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';

enum UserRole { student, cr, lecturer, staff, daruso, admin }

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({Key? key, required this.role}) : super(key: key);

  String _getLabel() {
    switch (role) {
      case UserRole.student: return 'Student';
      case UserRole.cr: return 'CR';
      case UserRole.lecturer: return 'Lecturer';
      case UserRole.staff: return 'Staff';
      case UserRole.daruso: return 'DARUSO';
      case UserRole.admin: return 'Admin';
    }
  }

  Color _getColor() {
    switch (role) {
      case UserRole.student: return Colors.transparent; // Not typically badged
      case UserRole.cr: return AppColors.roleCr;
      case UserRole.lecturer: return AppColors.roleLecturer;
      case UserRole.staff: return const Color(0xFF6A1B9A);
      case UserRole.daruso: return AppColors.roleDaruso;
      case UserRole.admin: return const Color(0xFF37474F);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.student) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: AppShapes.roleBadgeBorderRadius,
      ),
      child: Text(
        _getLabel(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
