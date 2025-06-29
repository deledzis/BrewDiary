class BrewingMethod {
  final int id;
  final String code;

  BrewingMethod({required this.id, required this.code});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
    };
  }

  factory BrewingMethod.fromMap(Map<String, dynamic> map) {
    return BrewingMethod(
      id: map['id'] as int,
      code: map['code'] as String,
    );
  }
}
