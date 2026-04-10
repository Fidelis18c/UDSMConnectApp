import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';
import '../widgets/compose_form_fields.dart';
import '../widgets/banner_photo_picker.dart';

class ComposeAnnouncementScreen extends ConsumerStatefulWidget {
  const ComposeAnnouncementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ComposeAnnouncementScreen> createState() => _ComposeAnnouncementScreenState();
}

class _ComposeAnnouncementScreenState extends ConsumerState<ComposeAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _selectedImageUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onPost() {
    if (_bodyController.text.trim().isEmpty) return;

    final user = ref.read(userProvider);

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: user.name.isNotEmpty ? user.name : 'Guest User',
      authorProfilePic: user.profilePic,
      text: _bodyController.text.trim(),
      imageUrl: _selectedImageUrl,
      timestamp: DateTime.now(),
      likes: 0,
      category: 'Class Update',
    );

    ref.read(announcementsProvider.notifier).addPost(newPost);
    context.pop();
  }

  void _pickBanner() {
    // Simulated Image Picker Logic
    setState(() {
      _selectedImageUrl = 'https://www.udsm.ac.tz/upload/20230531_020942_UDSM_CONVOCATION_7_NEW.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
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
                      const SizedBox(height: 24),
                      ComposeFormFields(
                        titleController: _titleController,
                        bodyController: _bodyController,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              UdsmButton(
                onPressed: _onPost,
                label: 'Post',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
