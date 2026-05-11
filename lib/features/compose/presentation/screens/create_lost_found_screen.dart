import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/widgets/udsm_button.dart';
import 'package:udsm_connect/core/widgets/udsm_text_field.dart';
import 'package:udsm_connect/core/widgets/udsm_dropdown.dart';
import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';

class CreateLostFoundScreen extends ConsumerStatefulWidget {
  const CreateLostFoundScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateLostFoundScreen> createState() => _CreateLostFoundScreenState();
}

class _CreateLostFoundScreenState extends ConsumerState<CreateLostFoundScreen> {
  final _itemController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedType = 'Lost';

  @override
  void dispose() {
    _itemController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_itemController.text.trim().isEmpty) return;

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'Fidelis Joseph',
      authorProfilePic: 'https://i.pravatar.cc/150?u=FJ',
      text: '${_selectedType == 'Lost' ? '[LOST]' : '[FOUND]'} '
          'Item: ${_itemController.text.trim()}\n'
          'Location: ${_locationController.text.trim()}\n'
          'Description: ${_descController.text.trim()}',
      timestamp: DateTime.now(),
      category: 'Lost and Found',
    );

    ref.read(announcementsProvider.notifier).prependLocal(newPost);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UdsmDropdown<String>(
                        value: _selectedType,
                        hint: 'Report Type',
                        items: const [
                          DropdownMenuItem(value: 'Lost', child: Text('I lost something')),
                          DropdownMenuItem(value: 'Found', child: Text('I found something')),
                        ],
                        onChanged: (val) => setState(() => _selectedType = val),
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _itemController,
                        hint: 'Item Name',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      UdsmTextField(
                        controller: _locationController,
                        hint: 'Location (e.g. Near Library)',
                        prefixIcon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '+ Add Image (Optional)',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              UdsmButton(
                onPressed: _onSubmit,
                label: 'Submit Report',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
