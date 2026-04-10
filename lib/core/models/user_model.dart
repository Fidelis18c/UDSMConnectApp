class UserModel {
  final String id;
  final String name;
  final String registrationNumber;
  final String college;
  final String programme;
  final String year;
  final String email;
  final String? profilePic;

  UserModel({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.college,
    required this.programme,
    required this.year,
    required this.email,
    this.profilePic,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? registrationNumber,
    String? college,
    String? programme,
    String? year,
    String? email,
    String? profilePic,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      college: college ?? this.college,
      programme: programme ?? this.programme,
      year: year ?? this.year,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
    );
  }
}
