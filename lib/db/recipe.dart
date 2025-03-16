class Recipe {
  final int? id;
  final String name;
  final String description;
  final String instructions;
  final int? grindSizeId;
  final bool isFavorite;
  final int? methodId;
  final int coffeeGrams;
  final int waterVolume;
  final int waterTemperature;
  final bool isPublic;
  final DateTime createdDate;

  Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.instructions,
    this.grindSizeId,
    this.isFavorite = false,
    this.methodId,
    required this.coffeeGrams,
    required this.waterVolume,
    required this.waterTemperature,
    this.isPublic = false,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructions': instructions,
      'grind_size_id': grindSizeId,
      'is_favorite': isFavorite ? 1 : 0,
      'method_id': methodId,
      'coffee_grams': coffeeGrams,
      'water_volume': waterVolume,
      'water_temperature': waterTemperature,
      'is_public': isPublic ? 1 : 0,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      instructions: map['instructions'] as String,
      grindSizeId: map['grind_size_id'] as int?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      methodId: map['method_id'] as int?,
      coffeeGrams: map['coffee_grams'] as int,
      waterVolume: map['water_volume'] as int,
      waterTemperature: map['water_temperature'] as int,
      isPublic: (map['is_public'] as int?) == 1,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }
}
