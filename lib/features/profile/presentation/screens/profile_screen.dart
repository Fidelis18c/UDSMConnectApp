import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/features/profile/presentation/widgets/profile_info_card.dart';
import 'package:udsm_connect/features/profile/presentation/widgets/action_list_card.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _onEditProfile(BuildContext context) {
    context.pushNamed(RouteNames.editProfile);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final initials = user.name.isNotEmpty 
        ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              AvatarInitials(
                initials: initials,
                imageUrl: user.profilePic,
                radius: 40,
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 40),
              ProfileInfoCard(user: user),
              const SizedBox(height: 24),
              ActionListCard(
                onChangePasswordLabel: () => _onEditProfile(context),
                onChangeEmailLabel: () => _onEditProfile(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
