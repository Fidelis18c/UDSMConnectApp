import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';

class UserNotifier extends Notifier<UserModel> {
  @override
  UserModel build() {
    // Return empty model initially
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

  void updateProfile({
    String? name,
    String? email,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
    );
  }
}

final userProvider = NotifierProvider<UserNotifier, UserModel>(() {
  return UserNotifier();
});
