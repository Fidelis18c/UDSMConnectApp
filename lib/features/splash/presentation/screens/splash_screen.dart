import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../navigation/route_names.dart';
import '../../../../core/widgets/udsm_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/user_provider.dart';

/// Entry screen: restores a saved session (stay logged in) or shows Get started.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await ref.read(authProvider.notifier).restoreSession();
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.user != null) {
      ref.read(userProvider.notifier).syncFromAuth(auth.user!);
      // Refresh full profile in the background when online.
      ref.read(userProvider.notifier).fetchProfile(auth.user!.id);
      context.goNamed(RouteNames.announcements);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final checkingSession = !auth.isInitialized || auth.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/UDSMlogo.png',
                height: 100,
              ),
              const SizedBox(height: 48),
              Text(
                'Welcome to\nUDSM Connect',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 16),
              Text(
                checkingSession
                    ? 'Signing you in…'
                    : "Let's personalize your experience",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              const Spacer(),
              if (checkingSession)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                UdsmButton(
                  onPressed: () {
                    context.goNamed(RouteNames.login);
                  },
                  label: 'Get started',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
