import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/features/events/presentation/providers/events_provider.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/models/event.dart';
import '../widgets/event_card.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: Column(
        children: [
          _buildCategoryFilters(context, ref),
          Expanded(
            child: events.when(
              data: (eventList) => eventList.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.event_busy_outlined,
                      message: 'No upcoming events yet',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: eventList.length,
                      itemBuilder: (context, index) {
                        final event = eventList[index];
                        return EventCard(
                          event: event,
                          onTap: () => context.pushNamed(
                            RouteNames.eventDetail,
                            pathParameters: {'id': event.id},
                            extra: event,
                          ),
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
        onPressed: () => context.pushNamed(RouteNames.createEvent),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(eventCategoriesProvider);
    final selectedId = ref.watch(selectedEventCategoryIdProvider);

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
                  onSelected: (_) => ref.read(selectedEventCategoryIdProvider.notifier).set(null),
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
                    ref.read(selectedEventCategoryIdProvider.notifier).set(selected ? cat.id : null);
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
