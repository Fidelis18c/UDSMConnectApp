import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../navigation/route_names.dart';
import '../../../../core/widgets/udsm_button.dart';
import '../../../../core/widgets/udsm_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../profile/presentation/providers/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // If session was restored while on another route, or user lands here with a
    // valid session, skip the form.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        final u = auth.user;
        if (u != null) {
          ref.read(userProvider.notifier).syncFromAuth(u);
        }
        context.goNamed(RouteNames.announcements);
      }
    });
  }

  void _onLogin() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).login(identifier, password);

    if (!mounted) return;
    final authState = ref.read(authProvider);

    if (ok && authState.isAuthenticated) {
      final u = authState.user;
      if (u != null) {
        ref.read(userProvider.notifier).syncFromAuth(u);
      }
      context.goNamed(RouteNames.announcements);
      return;
    }

    // Unverified new accounts → webmail OTP screen
    if (authState.otpPurpose == OtpPurpose.emailVerification &&
        authState.resetEmail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authState.error ??
                'Verify your @student.udsm.ac.tz mail (studentmail.udsm.ac.tz) to continue.',
          ),
        ),
      );
      // Ensure an OTP is sent (registration already may have sent one)
      await ref.read(authProvider.notifier).requestOtp(
            authState.resetEmail!,
            purpose: OtpPurpose.emailVerification,
          );
      if (mounted) context.pushNamed(RouteNames.verifyOtp);
      return;
    }

    if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/UDSMlogo.png',
                                height: 80,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Welcome Back',
                                style: Theme.of(context).textTheme.displayLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'sign in to UDSM connect',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            UdsmTextField(
                              controller: _emailController,
                              hint: 'Email or registration number',
                              prefixIcon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            UdsmTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.pushNamed(RouteNames.forgotPassword),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            UdsmButton(
                              onPressed: authState.isLoading ? null : _onLogin,
                              label: authState.isLoading ? 'Signing in...' : 'sign in',
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: () => context.pushNamed(RouteNames.register),
                                  child: Text(
                                    'sign up',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
