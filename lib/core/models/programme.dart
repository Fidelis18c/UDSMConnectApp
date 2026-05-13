class Programme {
  final String id;
  final String name;
  final String code;
  final int durationYears;
  final String? collegeName;

  Programme({
    required this.id,
    required this.name,
    required this.code,
    required this.durationYears,
    this.collegeName,
  });

  factory Programme.fromJson(Map<String, dynamic> json) {
    return Programme(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      durationYears: json['durationYears'] ?? 3,
      collegeName: json['collegeName'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Programme && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
