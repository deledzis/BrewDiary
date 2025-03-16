class BrewingMethod {
  final int? id;
  final String name;

  BrewingMethod({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory BrewingMethod.fromMap(Map<String, dynamic> map) {
    return BrewingMethod(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
}
