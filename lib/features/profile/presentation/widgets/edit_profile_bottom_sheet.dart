import 'package:flutter/material.dart';

import 'package:udsm_connect/core/models/user_model.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';

/// Modal bottom sheet: edit profile fields (pre-filled).
Future<void> showEditProfileBottomSheet(
  BuildContext context, {
  required UserModel user,
  required Future<void> Function({
    required String name,
    required String registrationNumber,
    required String programme,
    required String college,
    required String email,
    required String phone,
    required String year,
  }) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    barrierColor: Colors.black54,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return _EditProfileBottomSheetBody(
        user: user,
        onSave: ({
          required name,
          required registrationNumber,
          required programme,
          required college,
          required email,
          required phone,
          required year,
        }) async {
          await onSave(
            name: name,
            registrationNumber: registrationNumber,
            programme: programme,
            college: college,
            email: email,
            phone: phone,
            year: year,
          );
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      );
    },
  );
}

class _EditProfileBottomSheetBody extends StatefulWidget {
  const _EditProfileBottomSheetBody({
    required this.user,
    required this.onSave,
  });

  final UserModel user;
  final Future<void> Function({
    required String name,
    required String registrationNumber,
    required String programme,
    required String college,
    required String email,
    required String phone,
    required String year,
  }) onSave;

  @override
  State<_EditProfileBottomSheetBody> createState() =>
      _EditProfileBottomSheetBodyState();
}

class _EditProfileBottomSheetBodyState extends State<_EditProfileBottomSheetBody> {
  late TextEditingController _name;
  late TextEditingController _id;
  late TextEditingController _programme;
  late TextEditingController _college;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _year;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u.name);
    _id = TextEditingController(text: u.registrationNumber);
    _programme = TextEditingController(text: u.programme);
    _college = TextEditingController(text: u.college);
    _email = TextEditingController(text: u.email);
    _phone = TextEditingController(text: u.phone);
    _year = TextEditingController(text: u.year);
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _programme.dispose();
    _college.dispose();
    _email.dispose();
    _phone.dispose();
    _year.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        name: _name.text.trim(),
        registrationNumber: _id.text.trim(),
        programme: _programme.text.trim(),
        college: _college.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        year: _year.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsetsBottom),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your details and save.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 20),
              UdsmTextField(
                controller: _name,
                hint: 'Name',
                labelText: 'Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              UdsmTextField(
                controller: _id,
                hint: 'Registration ID',
                labelText: 'Id',
                prefixIcon: Icons.badge_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              UdsmTextField(
                controller: _programme,
                hint: 'Programme',
                labelText: 'Programme',
                prefixIcon: Icons.school_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              UdsmTextField(
                controller: _college,
                hint: 'College',
                labelText: 'College',
                prefixIcon: Icons.apartment_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              UdsmTextField(
                controller: _email,
                hint: 'E-mail',
                labelText: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              UdsmTextField(
                controller: _phone,
                hint: 'Phone',
                labelText: 'Phone',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              UdsmTextField(
                controller: _year,
                hint: 'Year (e.g. 3rd)',
                labelText: 'Year',
                prefixIcon: Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 24),
              UdsmButton(
                onPressed: _submit,
                label: 'Save',
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
