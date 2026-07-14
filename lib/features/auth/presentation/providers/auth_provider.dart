import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/firebase/firebase_bootstrap.dart';
import 'package:udsm_connect/features/notifications/presentation/providers/notifications_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_response.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthState {
  final bool isLoading;
  final String? error;
  final UserData? user;
  final bool isAuthenticated;
  /// True after [AuthNotifier.restoreSession] has finished once.
  final bool isInitialized;
  final String? resetEmail;
  final String? resetToken;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
    this.isInitialized = false,
    this.resetEmail,
    this.resetToken,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserData? user,
    bool? isAuthenticated,
    bool? isInitialized,
    String? resetEmail,
    String? resetToken,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialized: isInitialized ?? this.isInitialized,
      resetEmail: resetEmail ?? this.resetEmail,
      resetToken: resetToken ?? this.resetToken,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  bool _restoreInFlight = false;

  @override
  AuthState build() {
    return AuthState();
  }

  /// Rehydrate session from disk (and validate with `/users/me` when online).
  Future<void> restoreSession() async {
    if (state.isInitialized || _restoreInFlight) return;
    _restoreInFlight = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        state = AuthState(
          isLoading: false,
          user: user,
          isAuthenticated: true,
          isInitialized: true,
        );
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadCountProvider);
        await registerFcmTokenIfPossible();
      } else {
        state = AuthState(isLoading: false, isInitialized: true);
      }
    } catch (_) {
      state = AuthState(isLoading: false, isInitialized: true);
    } finally {
      _restoreInFlight = false;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, isInitialized: true);
    try {
      final response = await _repository.login(email, password);
      state = state.copyWith(
        isLoading: false,
        user: response.user,
        isAuthenticated: true,
        isInitialized: true,
      );
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      await registerFcmTokenIfPossible();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
        isInitialized: true,
      );
    }
  }

  Future<bool> register({
    required String fullName,
    required String registrationNumber,
    required String programmeId,
    required int yearOfStudy,
    required String sex,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register(
        fullName: fullName,
        registrationNumber: registrationNumber,
        programmeId: programmeId,
        yearOfStudy: yearOfStudy,
        sex: sex,
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> requestOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null, resetEmail: email);
    try {
      await _repository.requestPasswordReset(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String otpCode) async {
    if (state.resetEmail == null) {
      state = state.copyWith(error: 'Session expired. Please try again.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repository.verifyOtp(state.resetEmail!, otpCode);
      state = state.copyWith(isLoading: false, resetToken: token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    if (state.resetToken == null) {
      state = state.copyWith(error: 'Invalid session. Please try again.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.resetPassword(state.resetToken!, newPassword);
      state = AuthState(isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    // Unregister FCM while JWT is still valid, then clear session.
    await unregisterFcmTokenIfPossible();
    await _repository.logout();
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
    state = AuthState(isInitialized: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
