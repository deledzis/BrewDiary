import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();

  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _database;

  // Grinding sizes constants
  // TODO: localization
  static const String GRIND_TURKISH = 'turkish';
  static const String GRIND_EXTRA_FINE = 'extra_fine';
  static const String GRIND_FINE = 'fine';
  static const String GRIND_MEDIUM_FINE = 'medium_fine';
  static const String GRIND_MEDIUM = 'medium';
  static const String GRIND_MEDIUM_COARSE = 'medium_coarse';
  static const String GRIND_COARSE = 'coarse';

  static const List<String> GRIND_SIZES = [
    GRIND_TURKISH,
    GRIND_EXTRA_FINE,
    GRIND_FINE,
    GRIND_MEDIUM_FINE,
    GRIND_MEDIUM,
    GRIND_MEDIUM_COARSE,
    GRIND_COARSE,
  ];

  static const Map<String, String> GRIND_SIZE_NAMES = {
    GRIND_TURKISH: 'Turkish',
    GRIND_EXTRA_FINE: 'Extra Fine',
    GRIND_FINE: 'Fine',
    GRIND_MEDIUM_FINE: 'Medium Fine',
    GRIND_MEDIUM: 'Medium',
    GRIND_MEDIUM_COARSE: 'Medium Coarse',
    GRIND_COARSE: 'Coarse',
  };

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'brew_diary.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create brewing methods table
        await db.execute('''
          CREATE TABLE brewing_methods(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
        // Insert default brewing methods
        await db.insert('brewing_methods', {'name': 'V60'});
        await db.insert('brewing_methods', {'name': 'Espresso'});
        await db.insert('brewing_methods', {'name': 'Aeropress'});

        await db.execute('''
          CREATE TABLE brewing_results(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            method_id INTEGER,
            coffeeGrams INTEGER,
            waterVolume INTEGER,
            temperature INTEGER,
            aroma REAL,
            acidity REAL,
            sweetness REAL,
            body REAL,
            timestamp TEXT,
            recipeId INTEGER,
            imagePath TEXT,
            notes TEXT,
            FOREIGN KEY (method_id) REFERENCES brewing_methods(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE recipes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            instructions TEXT,
            grind_size TEXT,
            is_favorite INTEGER DEFAULT 0,
            method_id INTEGER,
            coffee_grams INTEGER,
            water_volume INTEGER,
            water_temperature INTEGER,
            FOREIGN KEY (method_id) REFERENCES brewing_methods(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE grinders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE grinder_click_settings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            grinder_id INTEGER,
            grind_size TEXT,
            min_clicks INTEGER,
            max_clicks INTEGER,
            FOREIGN KEY (grinder_id) REFERENCES grinders(id)
          )
        ''');
      },
    );
  }

  Future<int> saveGrinderClickSetting(Map<String, dynamic> setting) async {
    final db = await database;

    // Check if setting already exists
    List<Map<String, dynamic>> existing = await db.query(
        'grinder_click_settings',
        where: 'grinder_id = ? AND grind_size = ?',
        whereArgs: [setting['grinder_id'], setting['grind_size']]);

    if (existing.isNotEmpty) {
      // Update existing setting
      return await db.update('grinder_click_settings', setting,
          where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      // Insert new setting
      return await db.insert('grinder_click_settings', setting);
    }
  }

  Future<List<Map<String, dynamic>>> getGrinderClickSettings(
      int grinderId) async {
    final db = await database;
    return await db.query('grinder_click_settings',
        where: 'grinder_id = ?', whereArgs: [grinderId], orderBy: 'grind_size');
  }

  Future<int> insertMethod(Map<String, dynamic> method) async {
    final db = await database;
    return await db.insert('brewing_methods', method);
  }

  Future<List<Map<String, dynamic>>> getMethods() async {
    final db = await database;
    return await db.query('brewing_methods', orderBy: 'name');
  }

  Future<Map<String, dynamic>?> getMethodById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'brewing_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> insertGrinderSetting(Map<String, dynamic> setting) async {
    final db = await database;
    return await db.insert('grinder_settings', setting);
  }

  Future<List<Map<String, dynamic>>> getGrinderSettings(int grinderId) async {
    final db = await database;
    return await db.query('grinder_settings',
        where: 'grinder_id = ?', whereArgs: [grinderId], orderBy: 'method_id');
  }

  Future<int> updateGrinderSetting(Map<String, dynamic> setting) async {
    final db = await database;
    return await db.update(
      'grinder_settings',
      setting,
      where: 'id = ?',
      whereArgs: [setting['id']],
    );
  }

  Future<int> deleteGrinderSetting(int id) async {
    final db = await database;
    return await db
        .delete('grinder_settings', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBrewingResult(Map<String, dynamic> result) async {
    final db = await database;
    return await db.insert('brewing_results', result);
  }

  Future<List<Map<String, dynamic>>> getBrewingResults() async {
    final db = await database;
    return await db.query('brewing_results', orderBy: 'timestamp DESC');
  }

  Future<int> updateBrewingResult(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.update(
      'brewing_results',
      entry,
      where: 'id = ?',
      whereArgs: [entry['id']],
    );
  }

  Future<int> deleteBrewingResult(int id) async {
    final db = await database;
    return await db.delete('brewing_results', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getRecipeById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> insertRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    return await db.insert('recipes', recipe);
  }

  Future<List<Map<String, dynamic>>> getRecipes() async {
    final db = await database;
    return await db.query('recipes', orderBy: 'id DESC');
  }

  Future<int> updateRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    return await db.update(
      'recipes',
      recipe,
      where: 'id = ?',
      whereArgs: [recipe['id']],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertGrinder(Map<String, dynamic> grinder) async {
    final db = await database;
    return await db.insert('grinders', grinder);
  }

  Future<List<Map<String, dynamic>>> getGrinders() async {
    final db = await database;
    return await db.query('grinders', orderBy: 'id DESC');
  }

  Future<int> updateGrinder(Map<String, dynamic> grinder) async {
    final db = await database;
    // Extract id and ensure it's an int
    final id =
        grinder['id'] is String ? int.parse(grinder['id']) : grinder['id'];

    // Create a new map without the id to update
    final updates = Map<String, dynamic>.from(grinder);
    if (updates.containsKey('id')) {
      updates.remove('id');
    }

    return await db.update(
      'grinders',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGrinder(int id) async {
    final db = await database;
    return await db.delete('grinders', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getGrinderById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'grinders',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }
}
