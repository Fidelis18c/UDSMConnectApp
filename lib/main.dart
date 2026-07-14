import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  // Attach JWT early so the first API calls (session restore) are authenticated.
  // Full session restore + navigation is handled on the splash screen.
  final persisted = await AuthRepository().getToken();
  if (persisted != null && persisted.isNotEmpty) {
    ApiClient().setToken(persisted);
  }
  runApp(
    const ProviderScope(
      child: UdsmConnectApp(),
    ),
  );
}
