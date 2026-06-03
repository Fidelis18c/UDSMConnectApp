import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/models/college.dart';
import 'package:udsm_connect/core/models/department.dart';
import 'package:udsm_connect/core/models/programme.dart';
import 'package:udsm_connect/features/auth/presentation/widgets/searchable_college_dropdown.dart';
import 'package:udsm_connect/features/auth/presentation/widgets/searchable_department_dropdown.dart';
import 'package:udsm_connect/features/auth/presentation/widgets/searchable_programme_dropdown.dart';

import '../../../../core/theme/app_colors.dart';

enum AudienceUserRole { admin, collegeRep, classRep }

class AudienceSelection {
  final String targetType;
  final Programme? programme;
  final College? college;
  final Department? department;
  final int? year;

  AudienceSelection({
    required this.targetType,
    this.programme,
    this.college,
    this.department,
    this.year,
  });
}

class AudienceBottomSheet extends StatefulWidget {
  final AudienceSelection initialSelection;
  final AudienceUserRole userRole;
  final String? filterCollegeId;

  const AudienceBottomSheet({
    Key? key,
    required this.initialSelection,
    required this.userRole,
    this.filterCollegeId,
  }) : super(key: key);

  static Future<AudienceSelection?> show(
    BuildContext context, {
    required AudienceSelection initialSelection,
    required AudienceUserRole userRole,
    String? filterCollegeId,
  }) {
    return showModalBottomSheet<AudienceSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudienceBottomSheet(
        initialSelection: initialSelection,
        userRole: userRole,
        filterCollegeId: filterCollegeId,
      ),
    );
  }

  @override
  State<AudienceBottomSheet> createState() => _AudienceBottomSheetState();
}

class _AudienceBottomSheetState extends State<AudienceBottomSheet> {
  late String _targetType;
  Programme? _programme;
  College? _college;
  Department? _department;
  int? _year;

  @override
  void initState() {
    super.initState();
    _targetType = widget.initialSelection.targetType;
    _programme = widget.initialSelection.programme;
    _college = widget.initialSelection.college;
    _department = widget.initialSelection.department;
    _year = widget.initialSelection.year;
  }

  void _onDone() {
    Navigator.pop(
      context,
      AudienceSelection(
        targetType: _targetType,
        programme: _programme,
        college: _college,
        department: _department,
        year: _year,
      ),
    );
  }

  Widget _buildOptionRow({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _targetType == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _targetType = value;
          // Reset nested selections if completely changing types
          if (value == 'ALL') {
             _programme = null;
             _college = null;
             _department = null;
             _year = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                icon,
                color: isSelected ? AppColors.primary : theme.iconTheme.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const PhosphorIcon(
                PhosphorIconsBold.check,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Audience Targeting',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextButton(
                    onPressed: _onDone,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    child: const Text('Save'),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (widget.userRole == AudienceUserRole.admin) ...[
                      _buildOptionRow(
                        value: 'ALL',
                        icon: PhosphorIconsRegular.globeHemisphereWest,
                        title: 'All Students',
                        subtitle: 'Everyone at UDSM',
                      ),
                      _buildOptionRow(
                        value: 'COLLEGE',
                        icon: PhosphorIconsRegular.buildings,
                        title: 'Specific College',
                        subtitle: 'Target a specific college',
                      ),
                    ],
                    if (_targetType == 'COLLEGE' && widget.userRole == AudienceUserRole.admin)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: SearchableCollegeDropdown(
                          selectedCollege: _college,
                          onSelected: (c) => setState(() => _college = c),
                          hint: 'Search and select a college',
                        ),
                      ),
                    
                    _buildOptionRow(
                      value: 'DEPARTMENT',
                      icon: PhosphorIconsRegular.briefcase,
                      title: 'Specific Department',
                      subtitle: 'Target a specific department',
                    ),
                    if (_targetType == 'DEPARTMENT')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: SearchableDepartmentDropdown(
                          selectedDepartment: _department,
                          onSelected: (d) => setState(() => _department = d),
                          hint: 'Search and select a department',
                          filterCollegeId: widget.filterCollegeId,
                        ),
                      ),

                    _buildOptionRow(
                      value: 'PROGRAMME',
                      icon: PhosphorIconsRegular.graduationCap,
                      title: 'Specific Programme',
                      subtitle: 'Target a degree programme',
                    ),
                    if (_targetType == 'PROGRAMME' || _targetType == 'PROGRAMME_YEAR')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: SearchableProgrammeDropdown(
                          selectedProgramme: _programme,
                          onSelected: (p) => setState(() => _programme = p),
                          hint: 'Search and select a programme',
                          filterCollegeId: widget.filterCollegeId,
                        ),
                      ),

                    _buildOptionRow(
                      value: 'PROGRAMME_YEAR',
                      icon: PhosphorIconsRegular.calendarBlank,
                      title: 'Programme + Year',
                      subtitle: 'Target a specific year group',
                    ),
                    if (_targetType == 'PROGRAMME_YEAR')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: DropdownButtonFormField<int>(
                          value: _year,
                          decoration: InputDecoration(
                            hintText: 'Select Year of Study',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ),
                          ),
                          icon: const PhosphorIcon(PhosphorIconsRegular.caretDown, size: 20),
                          items: List.generate(
                            5,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('Year ${index + 1}'),
                            ),
                          ),
                          onChanged: (val) {
                            if (val != null) setState(() => _year = val);
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
