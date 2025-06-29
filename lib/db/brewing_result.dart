class BrewingResult {
  final int? id;
  final int? methodId;
  final int coffeeGrams;
  final int waterVolume;
  final int waterTemperature;
  final int? grindSizeId;
  final double aroma;
  final double acidity;
  final double sweetness;
  final double body;
  final DateTime timestamp;
  final int? recipeId;
  final String? notes;
  final DateTime createdDate;

  BrewingResult({
    this.id,
    this.methodId,
    required this.coffeeGrams,
    required this.waterVolume,
    required this.waterTemperature,
    this.grindSizeId,
    required this.aroma,
    required this.acidity,
    required this.sweetness,
    required this.body,
    required this.timestamp,
    this.recipeId,
    this.notes,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method_id': methodId,
      'coffee_grams': coffeeGrams,
      'water_volume': waterVolume,
      'water_temperature': waterTemperature,
      'grind_size_id': grindSizeId,
      'aroma': aroma,
      'acidity': acidity,
      'sweetness': sweetness,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'recipe_id': recipeId,
      'notes': notes,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory BrewingResult.fromMap(Map<String, dynamic> map) {
    return BrewingResult(
      id: map['id'] as int?,
      methodId: map['method_id'] as int?,
      coffeeGrams: map['coffee_grams'] as int,
      waterVolume: map['water_volume'] as int,
      waterTemperature: map['water_temperature'] as int,
      grindSizeId: map['grind_size_id'] as int?,
      aroma: map['aroma'] is int
          ? (map['aroma'] as int).toDouble()
          : map['aroma'] as double,
      acidity: map['acidity'] is int
          ? (map['acidity'] as int).toDouble()
          : map['acidity'] as double,
      sweetness: map['sweetness'] is int
          ? (map['sweetness'] as int).toDouble()
          : map['sweetness'] as double,
      body: map['body'] is int
          ? (map['body'] as int).toDouble()
          : map['body'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      recipeId: map['recipe_id'] as int?,
      notes: map['notes'] as String?,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }
}
