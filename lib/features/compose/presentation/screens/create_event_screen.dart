import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import 'package:udsm_connect/core/widgets/udsm_text_area.dart';
import 'package:udsm_connect/core/models/event.dart';
import 'package:udsm_connect/features/events/presentation/providers/events_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onCreate() {
    if (_titleController.text.trim().isEmpty) return;

    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      date: DateTime.now().add(const Duration(days: 7)), // Mock date for now
      location: _locationController.text.trim(),
      organizer: 'CoICT Students Council',
    );

    ref.read(eventsProvider.notifier).addEvent(newEvent);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Event'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UdsmTextField(
                        controller: _titleController,
                        hint: 'Event Title',
                        prefixIcon: Icons.title,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: UdsmTextField(
                              controller: _dateController,
                              hint: 'Date (DD/MM)',
                              prefixIcon: Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: UdsmTextField(
                              controller: _timeController,
                              hint: 'Time',
                              prefixIcon: Icons.access_time,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _locationController,
                        hint: 'Location (e.g. Nkrumah Hall)',
                        prefixIcon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),
                      UdsmTextArea(
                        controller: _descController,
                        hint: 'Event Description...',
                        maxLines: 6,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '+ Add Banner Image',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              UdsmButton(
                onPressed: _onCreate,
                label: 'Create Event',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
