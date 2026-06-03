class Department {
  final String id;
  final String name;
  final String? shortName;
  final String collegeId;

  Department({
    required this.id,
    required this.name,
    this.shortName,
    required this.collegeId,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String?,
      collegeId: json['collegeId'] as String,
    );
  }
}
