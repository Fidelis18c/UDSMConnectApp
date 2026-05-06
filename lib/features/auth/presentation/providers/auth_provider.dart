import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_response.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthState {
  final bool isLoading;
  final String? error;
  final UserData? user;
  final bool isAuthenticated;
  final String? resetEmail;
  final String? resetToken;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
    this.resetEmail,
    this.resetToken,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserData? user,
    bool? isAuthenticated,
    String? resetEmail,
    String? resetToken,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      resetEmail: resetEmail ?? this.resetEmail,
      resetToken: resetToken ?? this.resetToken,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(email, password);
      state = state.copyWith(
        isLoading: false,
        user: response.user,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> register({
    required String fullName,
    required String registrationNumber,
    required String course,
    required String sex,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register(
        fullName: fullName,
        registrationNumber: registrationNumber,
        course: course,
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
      state = AuthState(); // Reset everything on success
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
