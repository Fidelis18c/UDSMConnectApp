import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    ref.read(userProvider.notifier).updateProfile(
      name: _nameController.text,
      email: _emailController.text,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final initials = user.name.isNotEmpty 
        ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      // Trigger image picker logic
                    },
                    child: AvatarInitials(
                      initials: initials,
                      radius: 48,
                      showCameraIcon: true,
                    ),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UdsmTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    UdsmTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    UdsmTextField(
                      controller: _newPasswordController,
                      hint: 'New Password',
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 16),
                    UdsmTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 32),
                    UdsmButton(
                      onPressed: _onSubmit,
                      label: 'Submit',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
