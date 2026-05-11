import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
