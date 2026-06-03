class College {
  final String id;
  final String name;
  final String? acronym;

  College({
    required this.id,
    required this.name,
    this.acronym,
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] as String,
      name: json['name'] as String,
      acronym: json['acronym'] as String?,
    );
  }
}
