import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/features/lost_and_found/presentation/providers/lost_found_provider.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
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
            onPressed: () => ref.read(lostFoundItemsProvider.notifier).fetchItems(),
          ),
        ],
      ),
      body: lostFoundAsync.when(
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
                      // Show contact info or navigate to chat
                      if (item.contactInfo != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Contact: ${item.contactInfo}')),
                        );
                      }
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(RouteNames.createLostFound),
        child: const Icon(Icons.add),
      ),
    );
  }
}
