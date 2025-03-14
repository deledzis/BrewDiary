import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();

  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _database;

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
        // Таблица с результатами заваривания
        await db.execute('''
        CREATE TABLE brewing_results(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          method TEXT,
          coffeeGrams INTEGER,
          waterVolume INTEGER,
          temperature INTEGER,
          aroma REAL,
          acidity REAL,
          sweetness REAL,
          body REAL,
          timestamp TEXT
        )
      ''');
        // Таблица с рецептами
        await db.execute('''
        CREATE TABLE recipes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          description TEXT,
          instructions TEXT
        )
      ''');
      },
    );
  }

  Future<int> insertBrewingResult(Map<String, dynamic> result) async {
    final db = await database;
    return await db.insert('brewing_results', result);
  }

  Future<List<Map<String, dynamic>>> getBrewingResults() async {
    final db = await database;
    return await db.query('brewing_results', orderBy: 'timestamp DESC');
  }

  // Обновление записи
  Future<int> updateBrewingResult(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.update(
      'brewing_results',
      entry,
      where: 'id = ?',
      whereArgs: [entry['id']],
    );
  }

  // Удаление записи
  Future<int> deleteBrewingResult(int id) async {
    final db = await database;
    return await db.delete('brewing_results', where: 'id = ?', whereArgs: [id]);
  }

  // Добавление нового рецепта
  Future<int> insertRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    return await db.insert('recipes', recipe);
  }

  // Получение списка рецептов
  Future<List<Map<String, dynamic>>> getRecipes() async {
    final db = await database;
    return await db.query('recipes', orderBy: 'id DESC');
  }

  // Обновление рецепта
  Future<int> updateRecipe(Map<String, dynamic> recipe) async {
    final db = await database;
    return await db.update(
      'recipes',
      recipe,
      where: 'id = ?',
      whereArgs: [recipe['id']],
    );
  }

  // Удаление рецепта
  Future<int> deleteRecipe(int id) async {
    final db = await database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }
}
