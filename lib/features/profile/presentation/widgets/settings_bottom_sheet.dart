import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/theme_provider.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:udsm_connect/features/notifications/data/notification_repository.dart';
import 'package:udsm_connect/navigation/route_names.dart';

void showSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const SettingsBottomSheet(),
  );
}

class SettingsBottomSheet extends ConsumerStatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  ConsumerState<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends ConsumerState<SettingsBottomSheet> {
  bool? _postsNotifications;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final enabled = await NotificationRepository().getPostsPreference();
      if (mounted) {
        setState(() {
          _postsNotifications = enabled;
          _loadingPrefs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _postsNotifications = true;
          _loadingPrefs = false;
        });
      }
    }
  }

  Future<void> _setPostsNotifications(bool value) async {
    setState(() => _postsNotifications = value);
    try {
      await NotificationRepository().setPostsPreference(value);
    } catch (_) {
      if (mounted) {
        setState(() => _postsNotifications = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update notification preference')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: PhosphorIcon(
              isDarkMode ? PhosphorIconsFill.moon : PhosphorIconsRegular.moon,
            ),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          SwitchListTile(
            title: const Text('New post notifications'),
            subtitle: const Text('Push alerts when posts are published for you'),
            secondary: const PhosphorIcon(PhosphorIconsRegular.bell),
            value: _postsNotifications ?? true,
            onChanged: _loadingPrefs ? null : _setPostsNotifications,
            activeColor: Theme.of(context).primaryColor,
          ),
          const Divider(),
          ListTile(
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            leading: const PhosphorIcon(
              PhosphorIconsRegular.signOut,
              color: Colors.red,
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed(RouteNames.login);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
