import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/programme.dart';
import '../providers/programme_provider.dart';

class SearchableProgrammeDropdown extends ConsumerStatefulWidget {
  final Programme? selectedProgramme;
  final String? filterCollegeId;
  final Function(Programme) onSelected;
  final String hint;

  const SearchableProgrammeDropdown({
    Key? key,
    required this.selectedProgramme,
    this.filterCollegeId,
    required this.onSelected,
    this.hint = 'Select Programme',
  }) : super(key: key);

  @override
  ConsumerState<SearchableProgrammeDropdown> createState() => _SearchableProgrammeDropdownState();
}

class _SearchableProgrammeDropdownState extends ConsumerState<SearchableProgrammeDropdown> {
  final _searchController = TextEditingController();
  List<Programme> _filteredProgrammes = [];

  void _showSearchSheet(List<Programme> programmes) {
    _filteredProgrammes = programmes;
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search programme...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      _filteredProgrammes = programmes
                          .where((p) =>
                              p.name.toLowerCase().contains(value.toLowerCase()) ||
                              p.code.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredProgrammes.length,
                  itemBuilder: (context, index) {
                    final programme = _filteredProgrammes[index];
                    return ListTile(
                      title: Text(programme.name),
                      subtitle: Text(programme.code),
                      onTap: () {
                        widget.onSelected(programme);
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
    final programmeAsync = ref.watch(programmeProvider(widget.filterCollegeId));

    return InkWell(
      onTap: () {
        programmeAsync.whenData((programmes) {
          _showSearchSheet(programmes);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.book_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.selectedProgramme?.name ?? widget.hint,
                style: TextStyle(
                  color: widget.selectedProgramme == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (programmeAsync.isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}
