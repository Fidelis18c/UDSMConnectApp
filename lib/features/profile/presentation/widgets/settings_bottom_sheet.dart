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
  NotificationPreferences? _prefs;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await NotificationRepository().getPreferences();
      if (mounted) {
        setState(() {
          _prefs = prefs;
          _loadingPrefs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _prefs = const NotificationPreferences(
            posts: true,
            announcements: true,
            stories: true,
            lostFound: true,
          );
          _loadingPrefs = false;
        });
      }
    }
  }

  Future<void> _updatePref({
    bool? posts,
    bool? announcements,
    bool? stories,
    bool? lostFound,
  }) async {
    final current = _prefs ??
        const NotificationPreferences(
          posts: true,
          announcements: true,
          stories: true,
          lostFound: true,
        );

    final next = NotificationPreferences(
      posts: posts ?? current.posts,
      announcements: announcements ?? current.announcements,
      stories: stories ?? current.stories,
      lostFound: lostFound ?? current.lostFound,
    );

    setState(() => _prefs = next);

    try {
      await NotificationRepository().updatePreferences(
        posts: posts,
        announcements: announcements,
        stories: stories,
        lostFound: lostFound,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _prefs = current);
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
    final prefs = _prefs;

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
              // value true → dark, false → light
              ref.read(themeProvider.notifier).setTheme(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          const Divider(),
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Posts'),
            subtitle: const Text('New posts in your feed'),
            secondary: const PhosphorIcon(PhosphorIconsRegular.newspaper),
            value: prefs?.posts ?? true,
            onChanged: _loadingPrefs ? null : (v) => _updatePref(posts: v),
            activeColor: Theme.of(context).primaryColor,
          ),
          SwitchListTile(
            title: const Text('Announcements'),
            subtitle: const Text('Official announcements for you'),
            secondary: const PhosphorIcon(PhosphorIconsRegular.megaphone),
            value: prefs?.announcements ?? true,
            onChanged: _loadingPrefs ? null : (v) => _updatePref(announcements: v),
            activeColor: Theme.of(context).primaryColor,
          ),
          SwitchListTile(
            title: const Text('Stories'),
            subtitle: const Text('New stories in your college'),
            secondary: const PhosphorIcon(PhosphorIconsRegular.filmStrip),
            value: prefs?.stories ?? true,
            onChanged: _loadingPrefs ? null : (v) => _updatePref(stories: v),
            activeColor: Theme.of(context).primaryColor,
          ),
          SwitchListTile(
            title: const Text('Lost & Found'),
            subtitle: const Text('Reports in your college'),
            secondary: const PhosphorIcon(PhosphorIconsRegular.package),
            value: prefs?.lostFound ?? true,
            onChanged: _loadingPrefs ? null : (v) => _updatePref(lostFound: v),
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