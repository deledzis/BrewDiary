class GrindSize {
  final int id;
  final String code;

  GrindSize({required this.id, required this.code});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
    };
  }

  factory GrindSize.fromMap(Map<String, dynamic> map) {
    return GrindSize(
      id: map['id'] as int,
      code: map['code'] as String,
    );
  }
}
