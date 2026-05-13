import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import 'package:udsm_connect/core/widgets/udsm_text_area.dart';
import 'package:udsm_connect/core/widgets/udsm_dropdown.dart';
import 'package:udsm_connect/features/announcements/data/announcements_repository.dart';
import 'package:udsm_connect/features/lost_and_found/data/models/lost_found.dart';
import 'package:udsm_connect/features/lost_and_found/presentation/providers/lost_found_provider.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';

class CreateLostFoundScreen extends ConsumerStatefulWidget {
  const CreateLostFoundScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateLostFoundScreen> createState() => _CreateLostFoundScreenState();
}

class _CreateLostFoundScreenState extends ConsumerState<CreateLostFoundScreen> {
  final _itemController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();

  String? _selectedType = 'LOST';
  String? _selectedCategoryId;
  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _submitting = false;

  @override
  void dispose() {
    _itemController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _contactController.dispose();
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

  Future<void> _onSubmit() async {
    if (_itemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final announcementsRepo = ref.read(announcementsRepositoryProvider);
      final lostFoundNotifier = ref.read(lostFoundItemsProvider.notifier);

      List<String>? mediaIds;
      if (_imageBytes != null) {
        final mediaId = await announcementsRepo.uploadMediaBytes(
          _imageBytes!,
          filename: _imageFilename ?? 'item.jpg',
        );
        mediaIds = [mediaId];
      }

      final success = await lostFoundNotifier.createItem(
        title: _itemController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType!,
        categoryId: _selectedCategoryId,
        location: _locationController.text.trim(),
        contactInfo: _contactController.text.trim(),
        mediaIds: mediaIds,
      );

      if (success) {
        if (!mounted) return;
        context.pop();
      } else {
        throw Exception('Failed to create item');
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
    final categoriesAsync = ref.watch(lostFoundCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item'),
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
                      UdsmDropdown<String>(
                        value: _selectedType,
                        hint: 'Report Type',
                        items: const [
                          DropdownMenuItem(value: 'LOST', child: Text('I lost something')),
                          DropdownMenuItem(value: 'FOUND', child: Text('I found something')),
                        ],
                        onChanged: (val) => setState(() => _selectedType = val),
                      ),
                      const SizedBox(height: 16),
                      categoriesAsync.when(
                        data: (categories) => UdsmDropdown<String>(
                          value: _selectedCategoryId,
                          hint: 'Category',
                          items: categories
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Text('Error loading categories'),
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _itemController,
                        hint: 'Item Name',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _locationController,
                        hint: 'Location (e.g. Near Library)',
                        prefixIcon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _contactController,
                        hint: 'Contact Phone/Email',
                        prefixIcon: Icons.contact_phone_outlined,
                      ),
                      const SizedBox(height: 16),
                      UdsmTextArea(
                        controller: _descController,
                        hint: 'Detailed Description...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.white70),
                                      SizedBox(height: 8),
                                      Text(
                                        '+ Add Image (Optional)',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              UdsmButton(
                onPressed: _submitting ? null : _onSubmit,
                label: _submitting ? 'Submitting...' : 'Submit Report',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
