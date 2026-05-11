import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../features/auth/data/models/auth_response.dart';

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
