import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/features/lost_and_found/presentation/providers/lost_found_provider.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import '../widgets/lost_item_tile.dart';

class LostFoundScreen extends ConsumerWidget {
  const LostFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lostFoundAsync = ref.watch(lostFoundItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final categoryId = ref.read(selectedLostFoundCategoryIdProvider);
              ref.read(lostFoundItemsProvider.notifier).fetchItems(categoryId: categoryId);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilters(context, ref),
          Expanded(
            child: lostFoundAsync.when(
              data: (items) => items.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.search_off_outlined,
                      message: 'No items reported yet',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return LostItemTile(
                          item: item,
                          onContact: () {
                            if (item.contactInfo != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Contact: ${item.contactInfo}')),
                              );
                            }
                          },
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(RouteNames.createLostFound),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(lostFoundCategoriesProvider);
    final selectedId = ref.watch(selectedLostFoundCategoryIdProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 54,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: selectedId == null,
                  onSelected: (_) => ref.read(selectedLostFoundCategoryIdProvider.notifier).set(null),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.chipUnselected,
                  showCheckmark: false,
                  shape: const StadiumBorder(side: BorderSide.none),
                  labelStyle: TextStyle(
                    color: selectedId == null ? Colors.white : AppColors.textSecondary,
                    fontWeight: selectedId == null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat.name),
                  selected: selectedId == cat.id,
                  onSelected: (selected) {
                    ref.read(selectedLostFoundCategoryIdProvider.notifier).set(selected ? cat.id : null);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.chipUnselected,
                  showCheckmark: false,
                  shape: const StadiumBorder(side: BorderSide.none),
                  labelStyle: TextStyle(
                    color: selectedId == cat.id ? Colors.white : AppColors.textSecondary,
                    fontWeight: selectedId == cat.id ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              )),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 54,
        child: Center(child: LinearProgressIndicator(minHeight: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
