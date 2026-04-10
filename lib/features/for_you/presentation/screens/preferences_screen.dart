import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../navigation/route_names.dart';
import '../../../../core/widgets/udsm_button.dart';
import '../../../../core/widgets/udsm_checkbox.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final Map<String, bool> _preferences = {
    'Academic': true,
    'Financial & Scholarships': false,
    'Sports': false,
    'Campus Events': true,
    'General News': false,
  };

  void _onContinue() {
    context.goNamed(RouteNames.announcements);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Text(
                'What type of updates would you like to see?',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: _preferences.keys.map((key) {
                    return UdsmCheckbox(
                      value: _preferences[key]!,
                      onChanged: (val) {
                        setState(() {
                          _preferences[key] = val ?? false;
                        });
                      },
                      label: key,
                    );
                  }).toList(),
                ),
              ),
              UdsmButton(
                onPressed: _onContinue,
                label: 'Continue',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
