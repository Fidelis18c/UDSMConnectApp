import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/auth/data/models/auth_response.dart';
import '../../../../features/auth/data/users_repository.dart';

class UserNotifier extends Notifier<UserModel> {
  @override
  UserModel build() {
    return UserModel(
      id: 'guest',
      name: '',
      registrationNumber: '',
      college: '',
      programme: '',
      year: '',
      email: '',
    );
  }

  /// Sync cached profile UI from login / auth [`UserData`].
  void syncFromAuth(UserData user) {
    state = user.toUserModel();
  }

  Future<void> fetchProfile(String userId) async {
    try {
      final repo = ref.read(usersRepositoryProvider);
      final profile = await repo.fetchUser(userId);
      
      state = state.copyWith(
        name: profile.fullName,
        email: profile.email,
        registrationNumber: profile.registrationNumber ?? 'N/A',
        year: profile.yearOfStudy?.toString() ?? 'N/A',
        college: profile.collegeName ?? profile.collegeId ?? 'N/A',
        programme: profile.programmeName ?? profile.programmeId ?? 'N/A',
      );
    } catch (e) {
      // Handle error or keep current state
    }
  }

  void updateProfile({
    String? name,
    String? email,
    String? registrationNumber,
    String? college,
    String? programme,
    String? year,
    String? phone,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
      registrationNumber: registrationNumber,
      college: college,
      programme: programme,
      year: year,
      phone: phone,
    );
  }
}

final userProvider = NotifierProvider<UserNotifier, UserModel>(() {
  return UserNotifier();
});
