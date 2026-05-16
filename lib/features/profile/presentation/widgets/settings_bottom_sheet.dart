import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/theme_provider.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
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

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Close the bottom sheet
              Navigator.of(context).pop();
              // Perform logout
              await ref.read(authProvider.notifier).logout();
              // Navigate to Login screen
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
