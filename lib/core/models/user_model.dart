class UserModel {
  final String id;
  final String name;
  final String registrationNumber;
  final String college;
  final String department;
  final String programme;
  final String year;
  final String email;

  /// Editable locally until the backend exposes [`users.phone`] on auth/profile.
  final String phone;

  final String? profilePic;

  UserModel({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.college,
    this.department = '',
    required this.programme,
    required this.year,
    required this.email,
    this.phone = '',
    this.profilePic,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? registrationNumber,
    String? college,
    String? department,
    String? programme,
    String? year,
    String? email,
    String? phone,
    String? profilePic,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      college: college ?? this.college,
      department: department ?? this.department,
      programme: programme ?? this.programme,
      year: year ?? this.year,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
    );
  }
}
