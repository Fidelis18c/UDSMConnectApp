import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../navigation/route_names.dart';
import '../../../../core/widgets/udsm_button.dart';
import '../../../../core/widgets/otp_digit_box.dart';
import '../providers/auth_provider.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _onVerify() async {
    final otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code')),
      );
      return;
    }

    final purpose = ref.read(authProvider).otpPurpose;
    final success = await ref.read(authProvider.notifier).verifyOtp(otpCode);

    if (!mounted) return;
    if (success) {
      if (purpose == OtpPurpose.emailVerification) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified. You can log in now.'),
          ),
        );
        context.goNamed(RouteNames.login);
      } else {
        context.goNamed(RouteNames.newPassword);
      }
    } else {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Invalid code')),
      );
    }
  }

  void _onResend() async {
    final ok = await ref.read(authProvider.notifier).resendCurrentOtp();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'A new code was sent if the email is registered.'
              : (ref.read(authProvider).error ?? 'Could not resend code'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isEmailVerify = authState.otpPurpose == OtpPurpose.emailVerification;
    final emailHint = authState.resetEmail;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      Text(
                        isEmailVerify ? 'Verify webmail' : 'Verification',
                        style: Theme.of(context).textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEmailVerify
                            ? 'Enter the 6-digit code sent to your UDSM webmail'
                            : 'Enter the 6-digit code sent to your email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                      if (emailHint != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          emailHint,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return OtpDigitBox(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            onChanged: (val) => _onOtpChanged(index, val),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      UdsmButton(
                        onPressed: authState.isLoading ? null : _onVerify,
                        label: authState.isLoading ? 'Verifying...' : 'Verify',
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: authState.isLoading ? null : _onResend,
                        child: const Text('Resend code'),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Center(
                          child: Text(
                            isEmailVerify
                                ? 'Open studentmail.udsm.ac.tz if you do not see the email.'
                                : 'Check spam if the code is missing.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
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
