import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/features/events/presentation/providers/events_provider.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
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
      body: events.when(
        data: (eventList) => eventList.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.event_busy_outlined,
                message: 'No upcoming events from CoICT yet',
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(RouteNames.createEvent),
        child: const Icon(Icons.add),
      ),
    );
  }
}
