import '../../db/db_helper.dart';
import '../../db/grinder.dart';

class GrindersRepository {
  final DBHelper dbHelper;

  GrindersRepository({required this.dbHelper});

  Future<int> insertGrinder(Grinder grinder) async {
    return dbHelper.insertGrinder(grinder);
  }

  Future<List<Grinder>> getAllGrinders() async {
    return dbHelper.getGrinders();
  }

  Future<int> updateGrinder(Grinder grinder) async {
    return dbHelper.updateGrinder(grinder);
  }

  Future<int> deleteGrinder(int id) async {
    return dbHelper.deleteGrinder(id);
  }

  Future<Grinder?> getGrinderById(int id) async {
    return dbHelper.getGrinderById(id);
  }
}
