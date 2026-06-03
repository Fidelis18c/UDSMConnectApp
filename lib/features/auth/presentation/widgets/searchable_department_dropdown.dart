import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/models/department.dart';
import '../providers/department_provider.dart';

class SearchableDepartmentDropdown extends ConsumerStatefulWidget {
  final Department? selectedDepartment;
  final String? filterCollegeId;
  final Function(Department) onSelected;
  final String hint;

  const SearchableDepartmentDropdown({
    Key? key,
    required this.selectedDepartment,
    this.filterCollegeId,
    required this.onSelected,
    this.hint = 'Select Department',
  }) : super(key: key);

  @override
  ConsumerState<SearchableDepartmentDropdown> createState() => _SearchableDepartmentDropdownState();
}

class _SearchableDepartmentDropdownState extends ConsumerState<SearchableDepartmentDropdown> {
  final _searchController = TextEditingController();
  List<Department> _filteredDepartments = [];

  void _showSearchSheet(List<Department> departments) {
    _filteredDepartments = departments;
    _searchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search department...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      _filteredDepartments = departments
                          .where((d) =>
                              d.name.toLowerCase().contains(value.toLowerCase()) ||
                              (d.shortName?.toLowerCase().contains(value.toLowerCase()) ?? false))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredDepartments.length,
                  itemBuilder: (context, index) {
                    final dept = _filteredDepartments[index];
                    return ListTile(
                      title: Text(dept.name),
                      subtitle: dept.shortName != null ? Text(dept.shortName!) : null,
                      onTap: () {
                        widget.onSelected(dept);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departmentAsync = ref.watch(departmentProvider(widget.filterCollegeId));

    return InkWell(
      onTap: () {
        departmentAsync.whenData((departments) {
          _showSearchSheet(departments);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsRegular.briefcase, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.selectedDepartment?.name ?? widget.hint,
                style: TextStyle(
                  color: widget.selectedDepartment == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (departmentAsync.isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const PhosphorIcon(PhosphorIconsRegular.caretDown, size: 20),
          ],
        ),
      ),
    );
  }
}
