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
import 'package:udsm_connect/core/models/programme.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';
import 'package:udsm_connect/core/models/post.dart';

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
  
  AudienceUserRole _userRole = AudienceUserRole.admin;
  String? _filterCollegeId;

  @override
  void initState() {
    super.initState();
    _audienceSelection = AudienceSelection(targetType: 'ALL');
    _checkRoleRestriction();
  }

  Future<void> _checkRoleRestriction() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      if (mounted) setState(() => _isLoadingRole = false);
      return;
    }
    
    try {
      final userProfile = await ref.read(usersRepositoryProvider).fetchUser(user.id);
      if (!mounted) return;
      
      final roles = userProfile.roleNames.map((r) => r.toLowerCase()).toList();
      if (roles.isEmpty && userProfile.roleName != null) {
        roles.add(userProfile.roleName!.toLowerCase());
      }
      
      bool isAdmin = roles.any((r) => r.contains('admin') || r.contains('staff'));
      bool isClassRep = roles.any((r) => r.contains('class') || r.contains('representative'));
      bool isCollegeRep = roles.any((r) => r.contains('daruso') || r.contains('college'));

      if (isAdmin) {
        setState(() {
          _userRole = AudienceUserRole.admin;
        });
      } else if (isClassRep) {
        setState(() {
          _userRole = AudienceUserRole.classRep;
          _isAudienceLocked = true;
          _lockedLabel = '${userProfile.programmeName ?? 'Class'} - Year ${userProfile.yearOfStudy ?? '?'}';
          _lockedNotice = 'Your role restricts targeting to your class only.';
          
          final programme = userProfile.programmeId != null 
              ? Programme(id: userProfile.programmeId!, code: userProfile.programmeName ?? 'Class', name: userProfile.programmeName ?? '', durationYears: 3)
              : null;
              
          _audienceSelection = AudienceSelection(
            targetType: 'PROGRAMME_YEAR',
            programme: programme,
            year: userProfile.yearOfStudy,
          );
        });
      } else if (isCollegeRep) {
        setState(() {
          _userRole = AudienceUserRole.collegeRep;
          _filterCollegeId = userProfile.collegeId;
          // Default to targeting the whole college — they can narrow it down to
          // a Department or Programme from the audience sheet if desired.
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
      maxWidth: 1280,
      imageQuality: 75,
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
    
    if (_userRole == AudienceUserRole.classRep) return;
    
    final result = await AudienceBottomSheet.show(
      context, 
      initialSelection: _audienceSelection,
      userRole: _userRole,
      filterCollegeId: _filterCollegeId,
    );
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
        return 'All Students';
      case 'PROGRAMME':
        return _audienceSelection.programme?.code ?? 'Specific Programme';
      case 'PROGRAMME_YEAR':
        return '${_audienceSelection.programme?.code ?? 'Programme'} - Year ${_audienceSelection.year ?? '?'}';
      case 'COLLEGE':
        if (_userRole == AudienceUserRole.collegeRep) {
          return 'Whole College';
        }
        return _audienceSelection.college?.name ?? 'Specific College';
      case 'DEPARTMENT':
        return _audienceSelection.department?.shortName ?? _audienceSelection.department?.name ?? 'Specific Department';
      default:
        return 'All Students';
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

      // Audience was already resolved in _checkRoleRestriction — no extra /users/me call.
      String? coverImageId;
      final bytes = _imageBytes;
      if (bytes != null && bytes.isNotEmpty) {
        coverImageId = await ref.read(announcementsRepositoryProvider).uploadMediaBytes(
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
        final collegeId = _audienceSelection.college?.id ?? _filterCollegeId;
        if (collegeId != null) {
          audiences.add({
            'targetType': 'COLLEGE',
            'collegeId': collegeId,
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

      // When no title is typed, promote the first line of the body to the
      // title and remove it from the body so it isn't shown twice.
      String finalTitle = title;
      String finalBody = bodyText;
      if (finalTitle.isEmpty) {
        final lines = bodyText.split('\n');
        finalTitle = lines.first.trim();
        final rest = lines.skip(1).join('\n').trim();
        if (rest.isNotEmpty) finalBody = rest;
      }

      final excerpt = finalBody.length > 500 ? finalBody.substring(0, 500) : finalBody;

      final postId = await postsRepo.createPost(
        title: finalTitle,
        content: finalBody,
        excerpt: excerpt,
        audiences: audiences,
        status: 'PUBLISHED',
        coverImageId: coverImageId,
        type: widget.postType ?? 'POST',
      );

      // Instant UI: show post + leave compose; full feed refresh is background-only.
      ref.read(announcementsProvider.notifier).prependLocal(
            Post(
              id: postId,
              title: finalTitle,
              text: finalBody,
              authorId: user.id,
              authorName: user.fullName,
              authorRole: user.roleNames.isNotEmpty ? user.roleNames.first : null,
              timestamp: DateTime.now(),
            ),
          );

      if (!mounted) return;
      context.pop();
      // ignore: unawaited_futures
      ref.read(announcementsProvider.notifier).refresh();
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
                foregroundColor: Colors.white,
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
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isAudienceLocked
                                        ? Theme.of(context).dividerColor
                                        : AppColors.primary,
                                    width: 1.2,
                                  ),
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
                        filled: false,
                        hintText: 'Title',
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
                    
                    const SizedBox(height: 4),

                    // Content section — plain on the page's dark background
                    TextField(
                      controller: _bodyController,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      minLines: 6,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        filled: false,
                        hintText: widget.bodyHint ?? "What's happening at UDSM?",
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).hintColor.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

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
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.image,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
