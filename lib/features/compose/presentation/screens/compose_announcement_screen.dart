import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/features/announcements/data/announcements_repository.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/auth/data/users_repository.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';

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
  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _submitting = false;

  static String _dioMessage(DioException e) {
    final dynamic d = e.response?.data;
    if (d is Map && d['message'] != null) return '${d['message']}';
    final code = e.response?.statusCode;
    return code != null ? 'Request failed ($code).' : 'Network error.';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    final name = xFile.name.trim().isEmpty ? 'cover.jpg' : xFile.name.trim();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageFilename = name;
    });
  }

  void _clearBanner() {
    setState(() {
      _imageBytes = null;
      _imageFilename = null;
    });
  }

  Future<void> _onPost() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (!authState.isAuthenticated || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to publish.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final bodyText = _bodyController.text.trim();
    if (title.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must be at least 3 characters.')),
      );
      return;
    }
    if (bodyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before posting.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final announcementsRepo = ref.read(announcementsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);

      UserProfile? profile;
      try {
        profile = await usersRepo.fetchUser(user.id);
      } catch (_) {
        profile = null;
      }

      String? coverImageId;
      final bytes = _imageBytes;
      if (bytes != null && bytes.isNotEmpty) {
        coverImageId = await announcementsRepo.uploadMediaBytes(
          bytes,
          filename: _imageFilename ?? 'cover.jpg',
        );
      }

      final audiences = AnnouncementsRepository.audiencesFor(profile);
      final excerpt =
          bodyText.length > 500 ? bodyText.substring(0, 500) : bodyText;

      await announcementsRepo.createAnnouncement(
        title: title,
        content: bodyText,
        excerpt: excerpt,
        audiences: audiences,
        status: 'PUBLISHED',
        coverImageId: coverImageId,
      );

      await ref.read(announcementsProvider.notifier).refresh();
      if (!mounted) return;
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dioMessage(e))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New announcement'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _submitting ? null : () => context.pop(),
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
                        imageBytes: _imageBytes,
                        onTap: () {
                          if (!_submitting) _pickBanner();
                        },
                        onClear: () {
                          if (!_submitting) _clearBanner();
                        },
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
                onPressed: _submitting ? null : _onPost,
                label: 'Publish',
                isLoading: _submitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
