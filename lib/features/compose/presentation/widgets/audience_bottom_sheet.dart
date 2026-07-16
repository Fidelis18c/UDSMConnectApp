import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/models/college.dart';
import 'package:udsm_connect/core/models/department.dart';
import 'package:udsm_connect/core/models/programme.dart';
import 'package:udsm_connect/features/auth/presentation/widgets/searchable_college_dropdown.dart';
import 'package:udsm_connect/features/auth/presentation/widgets/searchable_department_dropdown.dart';
import 'package:udsm_connect/features/auth/presentation/widgets/searchable_programme_dropdown.dart';

import '../../../../core/theme/app_colors.dart';

enum AudienceUserRole { admin, collegeRep, classRep, deptStaff }

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
  /// When set (lecturer/staff), programmes are limited to this department.
  final String? filterDepartmentId;
  final String? lockedDepartmentName;

  const AudienceBottomSheet({
    Key? key,
    required this.initialSelection,
    required this.userRole,
    this.filterCollegeId,
    this.filterDepartmentId,
    this.lockedDepartmentName,
  }) : super(key: key);

  static Future<AudienceSelection?> show(
    BuildContext context, {
    required AudienceSelection initialSelection,
    required AudienceUserRole userRole,
    String? filterCollegeId,
    String? filterDepartmentId,
    String? lockedDepartmentName,
  }) {
    return showModalBottomSheet<AudienceSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudienceBottomSheet(
        initialSelection: initialSelection,
        userRole: userRole,
        filterCollegeId: filterCollegeId,
        filterDepartmentId: filterDepartmentId,
        lockedDepartmentName: lockedDepartmentName,
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

  bool get _isDeptStaff => widget.userRole == AudienceUserRole.deptStaff;

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
    // Dept staff must keep their department on DEPARTMENT target
    final dept = _isDeptStaff
        ? (widget.initialSelection.department ?? _department)
        : _department;

    if (_isDeptStaff) {
      if (_targetType == 'PROGRAMME' && _programme == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a programme')),
        );
        return;
      }
      if (_targetType == 'PROGRAMME_YEAR' &&
          (_programme == null || _year == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select programme and year')),
        );
        return;
      }
    }

    Navigator.pop(
      context,
      AudienceSelection(
        targetType: _targetType,
        programme: _programme,
        college: _college,
        department: dept,
        year: _year,
      ),
    );
  }

  Widget _buildOptionRow({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _targetType == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _targetType = value;
          if (value == 'ALL') {
            _programme = null;
            _college = null;
            _department = null;
            _year = null;
          }
          if (value == 'DEPARTMENT') {
            _programme = null;
            _year = null;
          }
          if (value == 'PROGRAMME') {
            _year = null;
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final deptLabel =
        widget.lockedDepartmentName ?? _department?.name ?? 'your department';

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
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    child: Text('Save'),
                  )
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Admin ───────────────────────────────────────────
                    if (widget.userRole == AudienceUserRole.admin) ...[
                      _buildOptionRow(
                        value: 'ALL',
                        title: 'All Students',
                        subtitle: 'Everyone at UDSM',
                      ),
                      _buildOptionRow(
                        value: 'COLLEGE',
                        title: 'Specific College',
                        subtitle: 'Target a specific college',
                      ),
                    ],
                    if (_targetType == 'COLLEGE' &&
                        widget.userRole == AudienceUserRole.admin)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: SearchableCollegeDropdown(
                          selectedCollege: _college,
                          onSelected: (c) => setState(() => _college = c),
                          hint: 'Search and select a college',
                        ),
                      ),

                    // ── College rep ─────────────────────────────────────
                    if (widget.userRole == AudienceUserRole.collegeRep)
                      _buildOptionRow(
                        value: 'COLLEGE',
                        title: 'Whole College',
                        subtitle: 'All students in your college',
                      ),

                    // ── Dept staff / lecturer ───────────────────────────
                    if (_isDeptStaff) ...[
                      _buildOptionRow(
                        value: 'DEPARTMENT',
                        title: 'Whole Department',
                        subtitle: 'Everyone in $deptLabel',
                      ),
                      _buildOptionRow(
                        value: 'PROGRAMME',
                        title: 'Specific Programme',
                        subtitle: 'One degree programme in your department',
                      ),
                      if (_targetType == 'PROGRAMME' ||
                          _targetType == 'PROGRAMME_YEAR')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: SearchableProgrammeDropdown(
                            selectedProgramme: _programme,
                            onSelected: (p) => setState(() => _programme = p),
                            hint: 'Select programme in your department',
                            filterDepartmentId: widget.filterDepartmentId,
                            filterCollegeId: widget.filterCollegeId,
                          ),
                        ),
                      _buildOptionRow(
                        value: 'PROGRAMME_YEAR',
                        title: 'Programme + Year',
                        subtitle: 'e.g. Year 2 of a programme',
                      ),
                      if (_targetType == 'PROGRAMME_YEAR')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: DropdownButtonFormField<int>(
                            value: _year,
                            decoration: InputDecoration(
                              hintText: 'Select Year of Study',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const PhosphorIcon(
                              PhosphorIconsRegular.caretDown,
                              size: 20,
                            ),
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
                    ] else ...[
                      // ── Admin / college rep: department option ───────
                      if (widget.userRole != AudienceUserRole.classRep)
                        _buildOptionRow(
                          value: 'DEPARTMENT',
                          title: 'Specific Department',
                          subtitle: 'Target a specific department',
                        ),
                      if (_targetType == 'DEPARTMENT' &&
                          widget.userRole != AudienceUserRole.classRep)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: SearchableDepartmentDropdown(
                            selectedDepartment: _department,
                            onSelected: (d) => setState(() => _department = d),
                            hint: 'Search and select a department',
                            filterCollegeId: widget.filterCollegeId,
                          ),
                        ),

                      if (widget.userRole != AudienceUserRole.classRep)
                        _buildOptionRow(
                          value: 'PROGRAMME',
                          title: 'Specific Programme',
                          subtitle: 'Target a degree programme',
                        ),
                      if ((_targetType == 'PROGRAMME' ||
                              _targetType == 'PROGRAMME_YEAR') &&
                          widget.userRole != AudienceUserRole.classRep)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: SearchableProgrammeDropdown(
                            selectedProgramme: _programme,
                            onSelected: (p) => setState(() => _programme = p),
                            hint: 'Search and select a programme',
                            filterCollegeId: widget.filterCollegeId,
                          ),
                        ),

                      if (widget.userRole != AudienceUserRole.classRep)
                        _buildOptionRow(
                          value: 'PROGRAMME_YEAR',
                          title: 'Programme + Year',
                          subtitle: 'Target a specific year group',
                        ),
                      if (_targetType == 'PROGRAMME_YEAR' &&
                          widget.userRole != AudienceUserRole.classRep)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: DropdownButtonFormField<int>(
                            value: _year,
                            decoration: InputDecoration(
                              hintText: 'Select Year of Study',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const PhosphorIcon(
                              PhosphorIconsRegular.caretDown,
                              size: 20,
                            ),
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
                    ],
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
