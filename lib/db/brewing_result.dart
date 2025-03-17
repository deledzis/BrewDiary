class BrewingResult {
  final int? id;
  final int methodId;
  final int coffeeGrams;
  final int waterVolume;
  final int temperature;
  final double aroma;
  final double acidity;
  final double sweetness;
  final double body;
  final DateTime timestamp;
  final int? recipeId;
  final String? imagePath;
  final String? notes;
  final DateTime createdDate;

  BrewingResult({
    this.id,
    required this.methodId,
    required this.coffeeGrams,
    required this.waterVolume,
    required this.temperature,
    required this.aroma,
    required this.acidity,
    required this.sweetness,
    required this.body,
    required this.timestamp,
    this.recipeId,
    this.imagePath,
    this.notes,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method_id': methodId,
      'coffeeGrams': coffeeGrams,
      'waterVolume': waterVolume,
      'temperature': temperature,
      'aroma': aroma,
      'acidity': acidity,
      'sweetness': sweetness,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'recipeId': recipeId,
      'imagePath': imagePath,
      'notes': notes,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory BrewingResult.fromMap(Map<String, dynamic> map) {
    return BrewingResult(
      id: map['id'] as int?,
      methodId: map['method_id'] as int,
      coffeeGrams: map['coffeeGrams'] as int,
      waterVolume: map['waterVolume'] as int,
      temperature: map['temperature'] as int,
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
      recipeId: map['recipeId'] as int?,
      imagePath: map['imagePath'] as String?,
      notes: map['notes'] as String?,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }
}
