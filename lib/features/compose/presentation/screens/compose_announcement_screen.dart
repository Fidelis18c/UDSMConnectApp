import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/features/announcements/data/announcements_repository.dart';
import 'package:udsm_connect/features/announcements/data/posts_repository.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/auth/data/users_repository.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';

import '../widgets/audience_bottom_sheet.dart';

class ComposeAnnouncementScreen extends ConsumerStatefulWidget {
  final String? title;
  final String? bodyHint;
  final String? postType;

  const ComposeAnnouncementScreen({
    Key? key,
    this.title,
    this.bodyHint,
    this.postType,
  }) : super(key: key);

  @override
  ConsumerState<ComposeAnnouncementScreen> createState() => _ComposeAnnouncementScreenState();
}

class _ComposeAnnouncementScreenState extends ConsumerState<ComposeAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _submitting = false;
  
  // By default we don't show the separate title field until the user taps a button or types enough.
  // Actually, we'll just keep it visible but very minimalist
  bool _showTitle = true; // Let's keep it visible per the plan if it has a title.

  late AudienceSelection _audienceSelection;
  bool _isLoadingRole = true;
  bool _isAudienceLocked = false;
  String? _lockedLabel;
  String? _lockedNotice;

  @override
  void initState() {
    super.initState();
    _audienceSelection = AudienceSelection(targetType: 'ALL');
    _checkRoleRestriction();
  }

  Future<void> _checkRoleRestriction() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingRole = false);
      return;
    }
    try {
      final userProfile = await ref.read(usersRepositoryProvider).fetchUser(userId);
      if (!mounted) return;
      
      final roles = userProfile.roleName?.toLowerCase() ?? '';
      if (roles.contains('class_representative') && !roles.contains('admin') && !roles.contains('staff')) {
        setState(() {
          _isAudienceLocked = true;
          _lockedLabel = '📅 ${userProfile.programmeName ?? 'Class'} - Year ${userProfile.yearOfStudy ?? '?'}';
          _lockedNotice = 'Your role restricts targeting to your class only.';
          _audienceSelection = AudienceSelection(targetType: 'PROGRAMME_YEAR');
        });
      } else if ((roles.contains('daruso') || roles.contains('daruso leader')) && !roles.contains('admin') && !roles.contains('staff')) {
        setState(() {
          _isAudienceLocked = true;
          _lockedLabel = '🏛️ ${userProfile.collegeName ?? 'Your College'}';
          _lockedNotice = 'Your role restricts targeting to your college only.';
          _audienceSelection = AudienceSelection(targetType: 'COLLEGE');
        });
      }
    } catch (_) {
      // Keep default unrestricted if fetch fails
    } finally {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

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

  Future<void> _openAudienceSheet() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    final result = await AudienceBottomSheet.show(context, initialSelection: _audienceSelection);
    if (result != null) {
      setState(() {
        _audienceSelection = result;
      });
    }
  }

  String get _audienceLabel {
    if (_isAudienceLocked && _lockedLabel != null) {
      return _lockedLabel!;
    }
    switch (_audienceSelection.targetType) {
      case 'ALL':
        return '🌍 All Students';
      case 'PROGRAMME':
        return '🎓 ${_audienceSelection.programme?.code ?? 'Specific Programme'}';
      case 'PROGRAMME_YEAR':
        return '📅 ${_audienceSelection.programme?.code ?? 'Programme'} - Year ${_audienceSelection.year ?? '?'}';
      case 'COLLEGE':
        return '🏛️ ${_audienceSelection.college?.name ?? 'Specific College'}';
      case 'DEPARTMENT':
        return '💼 ${_audienceSelection.department?.shortName ?? _audienceSelection.department?.name ?? 'Specific Department'}';
      default:
        return '🌍 All Students';
    }
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
    if (bodyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before posting.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final postsRepo = ref.read(postsRepositoryProvider);
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

      final List<Map<String, dynamic>> audiences = [];
      if (_audienceSelection.targetType == 'ALL') {
        audiences.add({'targetType': 'ALL'});
      } else if (_audienceSelection.targetType == 'PROGRAMME') {
        if (_audienceSelection.programme != null) {
          audiences.add({
            'targetType': 'PROGRAMME',
            'programmeId': _audienceSelection.programme!.id,
          });
        } else {
          audiences.add({'targetType': 'ALL'});
        }
      } else if (_audienceSelection.targetType == 'PROGRAMME_YEAR') {
        if (_audienceSelection.programme != null && _audienceSelection.year != null) {
          audiences.add({
            'targetType': 'PROGRAMME_YEAR',
            'programmeId': _audienceSelection.programme!.id,
            'yearOfStudy': _audienceSelection.year,
          });
        } else {
          audiences.add({'targetType': 'ALL'});
        }
      } else if (_audienceSelection.targetType == 'COLLEGE') {
        if (_audienceSelection.college != null) {
          audiences.add({
            'targetType': 'COLLEGE',
            'collegeId': _audienceSelection.college!.id,
          });
        } else {
          audiences.add({'targetType': 'ALL'});
        }
      } else if (_audienceSelection.targetType == 'DEPARTMENT') {
        if (_audienceSelection.department != null) {
          audiences.add({
            'targetType': 'DEPARTMENT',
            'departmentId': _audienceSelection.department!.id,
          });
        } else {
          audiences.add({'targetType': 'ALL'});
        }
      }

      final excerpt = bodyText.length > 500 ? bodyText.substring(0, 500) : bodyText;

      await postsRepo.createPost(
        title: title.isEmpty ? bodyText.split('\n')[0] : title,
        content: bodyText,
        excerpt: excerpt,
        audiences: audiences,
        status: 'PUBLISHED',
        coverImageId: coverImageId,
        type: widget.postType ?? 'POST',
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
    final user = ref.watch(userProvider);
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).join().toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'New Post',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.x),
          onPressed: _submitting ? null : () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: FilledButton(
              onPressed: _submitting ? null : _onPost,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Publish', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvatarInitials(initials: initials, radius: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: (_submitting || _isAudienceLocked) ? null : _openAudienceSheet,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isAudienceLocked
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isLoadingRole ? '...' : _audienceLabel,
                                      style: TextStyle(
                                        color: _isAudienceLocked
                                            ? Theme.of(context).hintColor
                                            : AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    PhosphorIcon(
                                      _isAudienceLocked
                                          ? PhosphorIconsRegular.lock
                                          : PhosphorIconsRegular.caretDown,
                                      color: _isAudienceLocked
                                          ? Theme.of(context).hintColor
                                          : AppColors.primary,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_lockedNotice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 52),
                        child: Text(
                          _lockedNotice!,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Inputs
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Title (Optional)',
                        hintStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).hintColor.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    
                    TextField(
                      controller: _bodyController,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: widget.bodyHint ?? "What's happening at UDSM?",
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).hintColor.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.only(top: 8, bottom: 24),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    // Image Preview
                    if (_imageBytes != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _submitting ? null : _clearBanner,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.6),
                              ),
                              icon: const PhosphorIcon(PhosphorIconsRegular.x, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Bottom Toolbar
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2))),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _submitting ? null : _pickBanner,
                        icon: const PhosphorIcon(PhosphorIconsRegular.image, color: AppColors.primary),
                        tooltip: 'Add Image',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
