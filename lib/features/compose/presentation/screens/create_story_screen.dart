import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udsm_connect/core/models/story.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/stories_provider.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import '../widgets/banner_photo_picker.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _collegeController = TextEditingController();
  String? _selectedImageUrl;

  @override
  void dispose() {
    _collegeController.dispose();
    super.dispose();
  }

  void _onPublish() {
    if (_collegeController.text.trim().isEmpty || _selectedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a college and attach a poster')),
      );
      return;
    }

    final newStory = Story(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      collegeName: _collegeController.text.trim(),
      imageUrl: _selectedImageUrl!,
    );

    ref.read(storiesProvider.notifier).addStory(newStory);
    context.pop();
  }

  void _pickBanner() {
    // Simulated Image Picker Logic
    setState(() {
      _selectedImageUrl = 'https://www.udsm.ac.tz/upload/20230608_085023_UDSM_ALUMNI_CONVOCATION.jpg';
    });
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
                        imageUrl: _selectedImageUrl,
                        onTap: _pickBanner,
                        onClear: () => setState(() => _selectedImageUrl = null),
                      ),
                      const SizedBox(height: 32),
                      UdsmTextField(
                        controller: _collegeController,
                        hint: 'College Name (e.g., CoICT, UDBS)',
                        prefixIcon: Icons.account_balance_outlined,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This story will be visible to all students in the top bar.',
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
                onPressed: _onPublish,
                label: 'Publish Story',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
