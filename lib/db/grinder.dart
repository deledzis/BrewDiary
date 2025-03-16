class Grinder {
  final int? id;
  final String name;
  final String? notes;

  Grinder({this.id, required this.name, this.notes});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
    };
  }

  factory Grinder.fromMap(Map<String, dynamic> map) {
    return Grinder(
      id: map['id'] as int?,
      name: map['name'] as String,
      notes: map['notes'] as String?,
    );
  }
}
