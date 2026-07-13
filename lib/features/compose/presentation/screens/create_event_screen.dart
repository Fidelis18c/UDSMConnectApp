import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
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
    final image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 70);
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
      initialDate: isStart 
          ? DateTime.now() 
          : (_startDateTime ?? DateTime.now()),
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
        if (_endDateTime != null && _endDateTime!.isBefore(dt)) {
          _endDateTime = dt.add(const Duration(hours: 1));
        }
      } else {
        _endDateTime = dt;
      }
    });
  }

  Future<void> _onCreate() async {
    if (_titleController.text.trim().isEmpty || _startDateTime == null || _endDateTime == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields, including Category')),
      );
      return;
    }

    if (_endDateTime!.isBefore(_startDateTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End Time must be after Start Time')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
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

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} • $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(eventCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner image picker
                    Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _imageBytes != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                                  Container(
                                    color: Colors.black.withOpacity(0.3),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                                  )
                                ],
                              )
                            : const Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                    ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          UdsmTextField(
                            controller: _titleController,
                            hint: 'Event Title',
                            prefixIcon: Icons.title,
                          ),
                          const SizedBox(height: 16),
                          categoriesAsync.when(
                            data: (List<EventCategory> categories) => UdsmDropdown<String>(
                              value: _selectedCategoryId,
                              hint: 'Select Category',
                              items: categories
                                  .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name)))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedCategoryId = val),
                            ),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, s) => const Text('Error loading categories'),
                          ),
                          const SizedBox(height: 16),
                          UdsmTextArea(
                            controller: _descController,
                            hint: 'What is this event about?',
                            maxLines: 4,
                          ),

                          const SizedBox(height: 32),
                          const Text('Timing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          _buildDateTimeTile(
                            label: 'Starts',
                            value: _startDateTime != null ? _formatDateTime(_startDateTime!) : 'Set start date & time',
                            icon: Icons.play_circle_outline,
                            onTap: () => _pickDateTime(true),
                            isActive: _startDateTime != null,
                          ),
                          const SizedBox(height: 12),
                          _buildDateTimeTile(
                            label: 'Ends',
                            value: _endDateTime != null ? _formatDateTime(_endDateTime!) : 'Set end date & time',
                            icon: Icons.stop_circle_outlined,
                            onTap: () => _pickDateTime(false),
                            isActive: _endDateTime != null,
                          ),

                          const SizedBox(height: 32),
                          const Text('Location & Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          UdsmTextField(
                            controller: _locationController,
                            hint: 'Physical Location',
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          UdsmTextField(
                            controller: _locationUrlController,
                            hint: 'Google Maps Link (Optional)',
                            prefixIcon: Icons.map_outlined,
                          ),
                          const SizedBox(height: 16),
                          UdsmTextField(
                            controller: _maxAttendeesController,
                            hint: 'Capacity (Optional)',
                            prefixIcon: Icons.groups_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: const Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: UdsmButton(
                onPressed: _submitting ? null : _onCreate,
                label: _submitting ? 'Publishing...' : 'Publish Event',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary.withOpacity(0.5) : AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: isActive ? AppColors.primary : AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
