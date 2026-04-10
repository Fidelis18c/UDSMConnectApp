import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import '../widgets/lost_item_tile.dart';

class LostFoundScreen extends ConsumerWidget {
  const LostFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPosts = ref.watch(announcementsProvider);
    final lostFoundItems = allPosts.where((post) => post.category == 'Lost and Found').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
      ),
      body: lostFoundItems.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.search_off_outlined,
              message: 'No items reported yet',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: lostFoundItems.length,
              itemBuilder: (context, index) {
                final item = lostFoundItems[index];
                return LostItemTile(
                  post: item,
                  onContact: () {
                    // Show contact info or navigate to chat
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(RouteNames.createLostFound),
        child: const Icon(Icons.add),
      ),
    );
  }
}
