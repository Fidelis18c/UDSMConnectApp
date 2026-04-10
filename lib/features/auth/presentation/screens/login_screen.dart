import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../navigation/route_names.dart';
import '../../../../core/widgets/udsm_button.dart';
import '../../../../core/widgets/udsm_text_field.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _regNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _regNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    // Scaffold UI logic simulating network
    context.goNamed(RouteNames.announcements);
  }

  @override
  Widget build(BuildContext context) {
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
                              controller: _regNumberController,
                              hint: 'Registration Number',
                              prefixIcon: Icons.person_outline,
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
                              onPressed: _onLogin,
                              label: 'sign in',
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
