import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../navigation/route_names.dart';
import '../../../../core/widgets/udsm_button.dart';
import '../../../../core/widgets/udsm_text_field.dart';
import '../../../../core/widgets/udsm_dropdown.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _programmeController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedSex;
  String? _selectedYear;

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _emailController.dispose();
    _programmeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_nameController.text.isEmpty ||
        _regNumberController.text.isEmpty ||
        _programmeController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          fullName: _nameController.text.trim(),
          registrationNumber: _regNumberController.text.trim(),
          course: _programmeController.text.trim(),
          sex: _selectedSex!.toUpperCase(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        context.goNamed(RouteNames.login);
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
                    hint: 'Registration Number',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  UdsmTextField(
                    controller: _programmeController,
                    hint: 'Programme (e.g BSc in CEIT)',
                    prefixIcon: Icons.book_outlined,
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
                          hint: 'Year',
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
                    hint: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
