import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import 'package:udsm_connect/core/widgets/udsm_text_area.dart';
import 'package:udsm_connect/core/widgets/udsm_dropdown.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/features/announcements/data/announcements_repository.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/lost_and_found/presentation/providers/lost_found_provider.dart';

class CreateLostFoundScreen extends ConsumerStatefulWidget {
  final String initialType;
  const CreateLostFoundScreen({super.key, this.initialType = 'LOST'});

  @override
  ConsumerState<CreateLostFoundScreen> createState() =>
      _CreateLostFoundScreenState();
}

class _CreateLostFoundScreenState
    extends ConsumerState<CreateLostFoundScreen> {
  final _itemController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();

  late String _selectedType;
  String? _selectedCategoryId;
  List<XFile> _selectedImages = [];
  bool _submitting = false;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

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
    final images = await picker.pickMultiImage(maxWidth: 1600, imageQuality: 70);
    if (images.isNotEmpty) {
      if (_selectedImages.length + images.length > 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only select up to 5 images')),
        );
        return;
      }
      setState(() {
        _selectedImages.addAll(images);
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

      List<String>? mediaIds;
      if (_selectedImages.isNotEmpty) {
        mediaIds = [];
        for (final file in _selectedImages) {
          final bytes = await file.readAsBytes();
          final mediaId = await announcementsRepo.uploadMediaBytes(
            bytes,
            filename: file.name,
          );
          mediaIds.add(mediaId);
        }
      }

      final success = await ref
          .read(lostFoundItemsProvider.notifier)
          .createItem(
            title: _itemController.text.trim(),
            description: _descController.text.trim(),
            type: _selectedType,
            categoryId: _selectedCategoryId,
            location: _locationController.text.trim(),
            contactInfo: _contactController.text.trim(),
            isAnonymous: _isAnonymous,
            mediaIds: mediaIds,
            dateLostFound: DateTime.now(), // default to today
          );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      } else {
        throw Exception('Server error: Failed to create report');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(lostFoundCategoriesProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _selectedType == 'LOST' ? 'Report Lost Item' : 'Report Found Item',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image Picker ─────────────────────────────────────────
              // Top image picker removed
              const SizedBox(height: 32),

              // ── Form Fields ──────────────────────────────────────────
              UdsmTextField(
                controller: _itemController,
                hint: 'Item Name',
                prefixIcon: Icons.edit_outlined,
              ),
              const SizedBox(height: 16),

              categoriesAsync.when(
                data: (categories) => UdsmDropdown<String>(
                  value: _selectedCategoryId,
                  hint: 'Select Category (Optional)',
                  items: categories
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, s) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Failed to load categories',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 16),

              UdsmTextField(
                controller: _locationController,
                hint: 'Location (e.g. CIVE Block B)',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),

              UdsmTextField(
                controller: _contactController,
                hint: 'Contact (Phone / Email)',
                prefixIcon: Icons.contact_phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              UdsmTextArea(
                controller: _descController,
                hint: 'Additional details (color, brand, distinguishing marks)...',
                maxLines: 4,
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<Uint8List>(
                        future: _selectedImages[index].readAsBytes(),
                        builder: (context, snapshot) {
                          return Container(
                            width: 120,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (snapshot.hasData)
                                  Image.memory(snapshot.data!, fit: BoxFit.cover)
                                else
                                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _pickImage,
                  icon: Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // ── Anonymous Checkbox ───────────────────────────────────
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isAnonymous,
                      onChanged: (v) => setState(() => _isAnonymous = v!),
                      activeColor: AppColors.primary,
                      side: BorderSide(color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Post Anonymously',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // ── Submit Button ────────────────────────────────────────
              UdsmButton(
                onPressed: _submitting ? null : _onSubmit,
                label: _submitting ? 'Submitting...' : 'Post Report',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
