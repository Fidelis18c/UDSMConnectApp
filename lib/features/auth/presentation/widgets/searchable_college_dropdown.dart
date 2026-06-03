import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/models/college.dart';
import '../providers/college_provider.dart';

class SearchableCollegeDropdown extends ConsumerStatefulWidget {
  final College? selectedCollege;
  final Function(College) onSelected;
  final String hint;

  const SearchableCollegeDropdown({
    Key? key,
    required this.selectedCollege,
    required this.onSelected,
    this.hint = 'Select College',
  }) : super(key: key);

  @override
  ConsumerState<SearchableCollegeDropdown> createState() => _SearchableCollegeDropdownState();
}

class _SearchableCollegeDropdownState extends ConsumerState<SearchableCollegeDropdown> {
  final _searchController = TextEditingController();
  List<College> _filteredColleges = [];

  void _showSearchSheet(List<College> colleges) {
    _filteredColleges = colleges;
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
                    hintText: 'Search college...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      _filteredColleges = colleges
                          .where((c) =>
                              c.name.toLowerCase().contains(value.toLowerCase()) ||
                              (c.acronym?.toLowerCase().contains(value.toLowerCase()) ?? false))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredColleges.length,
                  itemBuilder: (context, index) {
                    final college = _filteredColleges[index];
                    return ListTile(
                      title: Text(college.name),
                      subtitle: college.acronym != null ? Text(college.acronym!) : null,
                      onTap: () {
                        widget.onSelected(college);
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
    final collegeAsync = ref.watch(collegeProvider);

    return InkWell(
      onTap: () {
        collegeAsync.whenData((colleges) {
          _showSearchSheet(colleges);
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
            PhosphorIcon(PhosphorIconsRegular.buildings, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.selectedCollege?.name ?? widget.hint,
                style: TextStyle(
                  color: widget.selectedCollege == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (collegeAsync.isLoading)
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
