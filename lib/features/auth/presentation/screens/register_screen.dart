import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../navigation/route_names.dart';
import '../../../../core/widgets/udsm_button.dart';
import '../../../../core/widgets/udsm_text_field.dart';
import '../../../../core/widgets/udsm_dropdown.dart';
import '../../../../core/utils/student_identity.dart';
import '../providers/auth_provider.dart';
import '../../../../core/models/programme.dart';
import '../widgets/searchable_programme_dropdown.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Programme? _selectedProgramme;
  String? _selectedSex;
  String? _selectedYear;

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_nameController.text.isEmpty ||
        _regNumberController.text.isEmpty ||
        _selectedProgramme == null ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedSex == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final identityError = StudentIdentity.validateRegistration(
      email: _emailController.text,
      registrationNumber: _regNumberController.text,
    );
    if (identityError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(identityError)),
      );
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    final yearOfStudy = int.tryParse(_selectedYear ?? '1') ?? 1;

    final success = await ref.read(authProvider.notifier).register(
          fullName: _nameController.text.trim(),
          registrationNumber:
              StudentIdentity.normalizeRegNumber(_regNumberController.text),
          programmeId: _selectedProgramme!.id,
          yearOfStudy: yearOfStudy,
          sex: _selectedSex!.toUpperCase(),
          email: StudentIdentity.normalizeEmail(_emailController.text),
          password: _passwordController.text.trim(),
        );

    if (mounted) {
      if (success) {
        final warn = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              warn ??
                  'Account created. Enter the code sent to your email.',
            ),
            duration: Duration(seconds: warn != null ? 8 : 4),
          ),
        );
        context.pushNamed(RouteNames.verifyOtp);
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Registration failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/UDSMlogo.png',
                    height: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create an Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Please fill in your details to continue',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                    controller: _regNumberController,
                    hint: 'Registration Number (e.g. 2022-04-13802)',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  SearchableProgrammeDropdown(
                    selectedProgramme: _selectedProgramme,
                    onSelected: (programme) => setState(() => _selectedProgramme = programme),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: UdsmDropdown<String>(
                          value: _selectedSex,
                          hint: 'Sex',
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                          ],
                          onChanged: (val) => setState(() => _selectedSex = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: UdsmDropdown<String>(
                          value: _selectedYear,
                          hint: 'Year of study',
                          items: const [
                            DropdownMenuItem(value: '1', child: Text('Year 1')),
                            DropdownMenuItem(value: '2', child: Text('Year 2')),
                            DropdownMenuItem(value: '3', child: Text('Year 3')),
                            DropdownMenuItem(value: '4', child: Text('Year 4')),
                          ],
                          onChanged: (val) => setState(() => _selectedYear = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  UdsmTextField(
                    controller: _emailController,
                    hint: 'Email (e.g. you@gmail.com)',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use any working email (Gmail, Yahoo, Outlook, etc.). '
                    'You will receive a 6-digit code there before you can log in.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.65),
                        ),
                  ),
                  const SizedBox(height: 16),
                  UdsmTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 32),
                  UdsmButton(
                    onPressed: authState.isLoading ? null : _onRegister,
                    label: authState.isLoading ? 'Creating account...' : 'Create an Account',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'After signup, check your email inbox for the verification code.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.65),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
