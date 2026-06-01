import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'navigation/app_router.dart';

class UdsmConnectApp extends ConsumerStatefulWidget {
  const UdsmConnectApp({super.key});

  @override
  ConsumerState<UdsmConnectApp> createState() => _UdsmConnectAppState();
}

class _UdsmConnectAppState extends ConsumerState<UdsmConnectApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ensureNotificationPermission();
      await registerFcmTokenIfPossible();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'UDSM Connect',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
