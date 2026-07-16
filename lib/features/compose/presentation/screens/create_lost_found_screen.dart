import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import 'package:udsm_connect/core/widgets/udsm_text_area.dart';
import 'package:udsm_connect/core/widgets/udsm_dropdown.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
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
    final images =
        await picker.pickMultiImage(maxWidth: 1600, imageQuality: 70);
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

      final success = await ref.read(lostFoundItemsProvider.notifier).createItem(
            title: _itemController.text.trim(),
            description: _descController.text.trim(),
            type: _selectedType,
            categoryId: _selectedCategoryId,
            location: _locationController.text.trim(),
            contactInfo: _contactController.text.trim(),
            isAnonymous: _isAnonymous,
            mediaIds: mediaIds,
            dateLostFound: DateTime.now(),
          );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        context.pop();
      } else {
        throw Exception('Failed to create report');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Failed to create report' : msg)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(lostFoundCategoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: onSurface),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _selectedType == 'LOST' ? 'Report Lost Item' : 'Report Found Item',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeChip(
                        label: 'Lost',
                        selected: _selectedType == 'LOST',
                        onTap: () => setState(() => _selectedType = 'LOST'),
                      ),
                    ),
                    Expanded(
                      child: _TypeChip(
                        label: 'Found',
                        selected: _selectedType == 'FOUND',
                        onTap: () => setState(() => _selectedType = 'FOUND'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              UdsmTextField(
                controller: _itemController,
                hint: 'Item name',
                prefixIcon: Icons.edit_outlined,
              ),
              const SizedBox(height: 16),

              categoriesAsync.when(
                data: (categories) => UdsmDropdown<String>(
                  value: _selectedCategoryId,
                  hint: 'Category (optional)',
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedCategoryId = val),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, s) => Text(
                  'Could not load categories',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
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
                hint: 'Contact (phone / email)',
                prefixIcon: Icons.contact_phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              UdsmTextArea(
                controller: _descController,
                hint: 'Details (colour, brand, marks…)',
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
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (snapshot.hasData)
                                  Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
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
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image_outlined, color: AppColors.primary),
                  label: Text(
                    'Add photos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isAnonymous,
                      onChanged: (v) =>
                          setState(() => _isAnonymous = v ?? false),
                      activeColor: AppColors.primary,
                      side: BorderSide(color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Post anonymously',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              UdsmButton(
                onPressed: _submitting ? null : _onSubmit,
                label: _submitting ? 'Submitting...' : 'Post report',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
