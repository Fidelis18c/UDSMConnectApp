class Programme {
  final String id;
  final String name;
  final String code;
  final int durationYears;
  final String? collegeName;
  final String? departmentId;
  final String? departmentName;

  Programme({
    required this.id,
    required this.name,
    required this.code,
    required this.durationYears,
    this.collegeName,
    this.departmentId,
    this.departmentName,
  });

  factory Programme.fromJson(Map<String, dynamic> json) {
    return Programme(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? json['shortName'] as String? ?? '',
      durationYears: (json['durationYears'] as num?)?.toInt() ?? 3,
      collegeName: json['collegeName'] as String?,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Programme && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
