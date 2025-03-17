import 'package:brew_diary/db/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'brewing_method.dart';
import 'brewing_result.dart';
import 'grind_size.dart';
import 'grinder.dart';
import 'grinder_click_setting.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();

  static Database? _database;

  // Private constructor to prevent external instantiation
  DBHelper._internal();

  // Factory constructor to return the single instance
  factory DBHelper() => _instance;

  // Grinding sizes constants
  static const String _grindTurkish = 'turkish';
  static const String _grindExtraFine = 'extra_fine';
  static const String _grindFine = 'fine';
  static const String _grindMediumFine = 'medium_fine';
  static const String _grindMedium = 'medium';
  static const String _grindMediumCoarse = 'medium_coarse';
  static const String _grindCoarse = 'coarse';

  static String getLocalizedGrindSize(String code, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case _grindTurkish:
        return l10n.turkish;
      case _grindExtraFine:
        return l10n.extraFine;
      case _grindFine:
        return l10n.fine;
      case _grindMediumFine:
        return l10n.mediumFine;
      case _grindMedium:
        return l10n.medium;
      case _grindMediumCoarse:
        return l10n.mediumCoarse;
      case _grindCoarse:
        return l10n.coarse;
      default:
        return code;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'brew_diary.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
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
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            nickname TEXT,
            created_date TEXT
          );
        ''');
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
            created_date TEXT,
            FOREIGN KEY (method_id) REFERENCES brewing_methods(id)
          )
        ''');
    await db.execute('''
          CREATE TABLE recipes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            instructions TEXT,
            grind_size_id INTEGER,
            is_favorite INTEGER DEFAULT 0,
            method_id INTEGER,
            coffee_grams INTEGER,
            water_volume INTEGER,
            water_temperature INTEGER,
            is_public INTEGER DEFAULT 0,
            created_date TEXT,
            FOREIGN KEY (method_id) REFERENCES brewing_methods(id),
            FOREIGN KEY (grind_size_id) REFERENCES grind_sizes(id)
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
          CREATE TABLE grind_sizes(
            id INTEGER PRIMARY KEY,
            code TEXT UNIQUE NOT NULL
          )
        ''');
    await db.insert('grind_sizes', {'id': 1, 'code': _grindTurkish});
    await db.insert('grind_sizes', {'id': 2, 'code': _grindExtraFine});
    await db.insert('grind_sizes', {'id': 3, 'code': _grindFine});
    await db.insert('grind_sizes', {'id': 4, 'code': _grindMediumFine});
    await db.insert('grind_sizes', {'id': 5, 'code': _grindMedium});
    await db.insert('grind_sizes', {'id': 6, 'code': _grindMediumCoarse});
    await db.insert('grind_sizes', {'id': 7, 'code': _grindCoarse});

    await db.execute('''
          CREATE TABLE grinder_click_settings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            grinder_id INTEGER,
            grind_size_id INTEGER,
            min_clicks INTEGER,
            max_clicks INTEGER,
            FOREIGN KEY (grinder_id) REFERENCES grinders(id),
            FOREIGN KEY (grind_size_id) REFERENCES grind_sizes(id)
          );
        ''');
  }

  /*
  * Grinder Click Settings
  */
  Future<int> insertOrUpdateGrinderClickSetting(
      GrinderClickSetting setting) async {
    final db = await database;

    // Check if setting already exists
    List<Map<String, dynamic>> existingData = await db.query(
        'grinder_click_settings',
        where: 'grinder_id = ? AND grind_size_id = ?',
        whereArgs: [setting.grinderId, setting.grindSizeId]);

    if (existingData.isNotEmpty) {
      final GrinderClickSetting existing =
          GrinderClickSetting.fromMap(existingData.first);
      setting.id = existing.id;
      // Update existing setting
      return await db.update('grinder_click_settings', setting.toMap(),
          where: 'id = ?', whereArgs: [existing.id]);
    } else {
      // Insert new setting
      return await db.insert('grinder_click_settings', setting.toMap());
    }
  }

  Future<List<GrinderClickSetting>> getGrinderClickSettings(
      int grinderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grinder_click_settings',
      where: 'grinder_id = ?',
      whereArgs: [grinderId],
      orderBy: 'grind_size_id',
    );
    return maps.map((map) => GrinderClickSetting.fromMap(map)).toList();
  }

  Future<GrinderClickSetting?> getGrinderClickSettingById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'grinder_click_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return GrinderClickSetting.fromMap(result.first);
    }
    return null;
  }

  Future<int> deleteGrinderClickSetting(int id) async {
    final db = await database;
    return await db.delete(
      'grinder_click_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /*
  * Grind Sizes
  */
  Future<List<GrindSize>> getGrindSizes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('grind_sizes', orderBy: 'id ASC');
    return maps.map((map) => GrindSize.fromMap(map)).toList();
  }

  Future<GrindSize?> getGrindSizeById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'grind_sizes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return GrindSize.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertGrindSize(GrindSize method) async {
    final db = await database;
    return await db.insert('grind_sizes', method.toMap());
  }

  Future<int> updateGrindSize(GrindSize entry) async {
    final db = await database;
    return await db.update(
      'grind_sizes',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteGrindSize(int id) async {
    final db = await database;
    return await db.delete(
      'grind_sizes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /*
  * Brewing Methods
  */
  Future<List<BrewingMethod>> getBrewingMethods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('brewing_methods', orderBy: 'name');
    return maps.map((map) => BrewingMethod.fromMap(map)).toList();
  }

  Future<BrewingMethod?> getBrewingMethodById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'brewing_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return BrewingMethod.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertBrewingMethod(BrewingMethod method) async {
    final db = await database;
    return await db.insert('brewing_methods', method.toMap());
  }

  Future<int> updateBrewingMethod(BrewingMethod entry) async {
    final db = await database;
    return await db.update(
      'brewing_methods',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteBrewingMethod(int id) async {
    final db = await database;
    return await db.delete(
      'brewing_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /*
  * Brewing Results
  */
  Future<List<BrewingResult>> getBrewingResults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('brewing_results', orderBy: 'timestamp DESC');
    return maps.map((map) => BrewingResult.fromMap(map)).toList();
  }

  Future<int> insertBrewingResult(BrewingResult result) async {
    final db = await database;
    return await db.insert('brewing_results', result.toMap());
  }

  Future<int> updateBrewingResult(BrewingResult entry) async {
    final db = await database;
    return await db.update(
      'brewing_results',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteBrewingResult(int id) async {
    final db = await database;
    return await db.delete(
      'brewing_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /*
  * Recipes
  */
  Future<List<Recipe>> getRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('recipes', orderBy: 'id DESC');
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Recipe.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await database;
    return await db.insert('recipes', recipe.toMap());
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await database;
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /*
  * Grinders
  */
  Future<List<Grinder>> getGrinders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('grinders', orderBy: 'id DESC');
    return maps.map((map) => Grinder.fromMap(map)).toList();
  }

  Future<Grinder?> getGrinderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grinders',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? Grinder.fromMap(maps.first) : null;
  }

  Future<int> insertGrinder(Grinder grinder) async {
    final db = await database;
    return await db.insert('grinders', grinder.toMap());
  }

  Future<int> updateGrinder(Grinder grinder) async {
    final db = await database;
    return await db.update(
      'grinders',
      grinder.toMap(),
      where: 'id = ?',
      whereArgs: [grinder.id],
    );
  }

  Future<int> deleteGrinder(int id) async {
    final db = await database;
    return await db.delete(
      'grinders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
