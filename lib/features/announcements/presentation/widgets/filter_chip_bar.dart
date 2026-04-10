import 'package:flutter/material.dart';
import '../../../../core/widgets/filter_chip_widget.dart';

class FilterChipBar extends StatefulWidget {
  final List<String> categories;
  final ValueChanged<String> onSelected;

  const FilterChipBar({
    Key? key,
    required this.categories,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<FilterChipBar> createState() => _FilterChipBarState();
}

class _FilterChipBarState extends State<FilterChipBar> {
  String _selectedCategory = 'All updates';

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          return Center(
            child: FilterChipWidget(
              label: category,
              isSelected: category == _selectedCategory,
              onTap: () {
                setState(() => _selectedCategory = category);
                widget.onSelected(category);
              },
            ),
          );
        },
      ),
    );
  }
}
