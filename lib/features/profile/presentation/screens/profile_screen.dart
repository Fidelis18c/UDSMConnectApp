import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/core/widgets/news_post_card.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_posts_provider.dart';
import 'package:udsm_connect/features/profile/presentation/widgets/edit_profile_bottom_sheet.dart';
import 'package:udsm_connect/features/profile/presentation/widgets/profile_info_card.dart';
import 'package:udsm_connect/navigation/route_names.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Uint8List? _localImageBytes;
  bool _uploadingPic = false;

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    setState(() => _localImageBytes = bytes);
    try {
      setState(() => _uploadingPic = true);
      final repo = ref.read(announcementsRepositoryProvider);
      final url = await repo.uploadMediaBytesGetUrl(bytes, filename: image.name);
      await ref.read(userProvider.notifier).updateProfilePic(url);
      setState(() => _localImageBytes = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload picture. Try again.')),
        );
        setState(() => _localImageBytes = null);
      }
    } finally {
      if (mounted) setState(() => _uploadingPic = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      if (user.id != 'guest') {
        ref.read(userProvider.notifier).fetchProfile(user.id);
      }
    });
  }

  void _popOrHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(RouteNames.announcements);
  }

  void _openEditSheet(BuildContext context) {
    final user = ref.read(userProvider);
    showEditProfileBottomSheet(
      context,
      user: user,
      onSave: ({
        required name,
        required registrationNumber,
        required programme,
        required college,
        required email,
        required phone,
        required year,
      }) async {
        await ref.read(userProvider.notifier).updateProfile(
              name: name,
              registrationNumber: registrationNumber,
              programme: programme,
              college: college,
              email: email,
              phone: phone,
              year: year,
            );
        return;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final initials = user.name.isNotEmpty
        ? user.name
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .join()
            .toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 132,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topLeft,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: AppColors.primary),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: IconButton(
                        onPressed: () => _popOrHome(context),
                        icon: Icon(
                          PhosphorIconsRegular.caretLeft,
                          size: 26,
                          color: AppColors.textPrimary.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _uploadingPic ? null : _pickProfilePicture,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              DecoratedBox(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x40000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.textPrimary.withValues(alpha: 0.9),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: _localImageBytes != null
                                      ? ClipOval(
                                          child: Image.memory(
                                            _localImageBytes!,
                                            width: 88,
                                            height: 88,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : AvatarInitials(
                                          initials: initials,
                                          imageUrl: user.profilePic,
                                          radius: 44,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.background,
                                      width: 2,
                                    ),
                                  ),
                                  child: _uploadingPic
                                      ? const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 52),
              Text(
                user.name.isEmpty ? 'Your profile' : user.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.15,
                    ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _openEditSheet(context),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Messages will be available soon.'),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            PhosphorIconsFill.chatCircle,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ProfileInfoCard(user: user),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Text(
                  'Posts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Consumer(
                  builder: (context, ref, child) {
                    if (user.id == 'guest' || user.id.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final postsAsync = ref.watch(userPostsProvider(user.id));
                    return postsAsync.when(
                      data: (posts) {
                        if (posts.isEmpty) {
                          return _buildEmptyState(context);
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return NewsPostCard(
                              post: post,
                              replyCount: post.commentCount,
                              onOpen: () => context.pushNamed(RouteNames.postDetail, extra: post.id),
                              onLike: () {}, // Optional: implement like toggle here
                              onReplyTap: () => context.pushNamed(RouteNames.postDetail, extra: post.id),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          'Error loading posts',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        'No posts yet.\nAnything you publish can show up here later.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
      ),
    );
  }
}
