import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:udsm_connect/features/compose/data/repositories/media_repository.dart';
import 'package:udsm_connect/features/stories/data/repositories/story_repository.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/stories_provider.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import '../widgets/banner_photo_picker.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _captionController = TextEditingController();
  XFile? _selectedFile;
  Uint8List? _selectedBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _onPublish() async {
    if (_selectedFile == null || _selectedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach an image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Upload media
      final mediaRepo = MediaRepository();
      final media = await mediaRepo.uploadBytes(_selectedBytes!, _selectedFile!.name);

      // 2. Create story
      final storyRepo = StoryRepository();
      await storyRepo.createStory(
        media.id,
        caption: _captionController.text.trim(),
      );

      // 3. Refresh Provider and close
      ref.read(storiesProvider.notifier).refresh();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story published successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (e is DioException && e.response != null) {
          final data = e.response?.data;
          if (data is Map && data.containsKey('message')) {
            errMsg = data['message'];
          } else {
            errMsg = data.toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errMsg')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedFile = image;
        _selectedBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Story'),
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
                    children: [
                      BannerPhotoPicker(
                        imageBytes: _selectedBytes,
                        onTap: _pickBanner,
                        onClear: () => setState(() {
                          _selectedFile = null;
                          _selectedBytes = null;
                        }),
                      ),
                      const SizedBox(height: 32),
                      UdsmTextField(
                        controller: _captionController,
                        hint: 'Caption (Optional)',
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This story will appear under your college\'s bubble\nin the stories tray.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white38,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              UdsmButton(
                onPressed: _isUploading ? null : _onPublish,
                label: _isUploading ? 'Publishing...' : 'Publish Story',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
