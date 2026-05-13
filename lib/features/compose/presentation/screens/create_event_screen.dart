import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import 'package:udsm_connect/core/widgets/udsm_text_area.dart';
import 'package:udsm_connect/core/widgets/udsm_dropdown.dart';
import 'package:udsm_connect/core/models/event.dart';
import 'package:udsm_connect/features/announcements/data/announcements_repository.dart';
import 'package:udsm_connect/features/events/presentation/providers/events_provider.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationUrlController = TextEditingController();
  final _maxAttendeesController = TextEditingController();

  DateTime? _startDateTime;
  DateTime? _endDateTime;
  String? _selectedCategoryId;
  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _locationUrlController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFilename = image.name;
      });
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startDateTime = dt;
      } else {
        _endDateTime = dt;
      }
    });
  }

  Future<void> _onCreate() async {
    if (_titleController.text.trim().isEmpty || _startDateTime == null || _endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final announcementsRepo = ref.read(announcementsRepositoryProvider);
      final eventsNotifier = ref.read(eventsProvider.notifier);

      String? coverImageId;
      if (_imageBytes != null) {
        coverImageId = await announcementsRepo.uploadMediaBytes(
          _imageBytes!,
          filename: _imageFilename ?? 'event.jpg',
        );
      }

      final Map<String, dynamic> eventData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'categoryId': _selectedCategoryId,
        'startDateTime': _startDateTime!.toUtc().toIso8601String(),
        'endDateTime': _endDateTime!.toUtc().toIso8601String(),
        'location': _locationController.text.trim(),
        'maxAttendees': int.tryParse(_maxAttendeesController.text.trim()),
        'coverImageId': coverImageId,
        'status': 'PUBLISHED',
      };

      if (_locationUrlController.text.trim().isNotEmpty) {
        eventData['locationUrl'] = _locationUrlController.text.trim();
      }

      final success = await eventsNotifier.createEvent(eventData);

      if (success) {
        if (!mounted) return;
        context.pop();
      } else {
        throw Exception('Failed to create event');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(eventCategoriesProvider);

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
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.white70),
                                      SizedBox(height: 8),
                                      Text(
                                        'Add Event Banner',
                                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      UdsmTextField(
                        controller: _titleController,
                        hint: 'Event Title',
                        prefixIcon: Icons.title,
                      ),
                      const SizedBox(height: 16),
                      categoriesAsync.when(
                        data: (List<EventCategory> categories) => UdsmDropdown<String>(
                          value: _selectedCategoryId,
                          hint: 'Category',
                          items: categories
                              .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Text('Error loading categories'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDateTime(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Starts', style: TextStyle(fontSize: 12, color: Colors.white60)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _startDateTime == null ? 'Select Date' : '${_startDateTime!.day}/${_startDateTime!.month} ${_startDateTime!.hour}:${_startDateTime!.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDateTime(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ends', style: TextStyle(fontSize: 12, color: Colors.white60)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _endDateTime == null ? 'Select Date' : '${_endDateTime!.day}/${_endDateTime!.month} ${_endDateTime!.hour}:${_endDateTime!.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _locationController,
                        hint: 'Physical Location',
                        prefixIcon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _locationUrlController,
                        hint: 'Map/Online Link (Optional)',
                        prefixIcon: Icons.link,
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _maxAttendeesController,
                        hint: 'Max Attendees (Optional)',
                        prefixIcon: Icons.people_outline,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      UdsmTextArea(
                        controller: _descController,
                        hint: 'Event Description...',
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              UdsmButton(
                onPressed: _submitting ? null : _onCreate,
                label: _submitting ? 'Creating...' : 'Create Event',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
