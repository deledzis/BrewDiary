import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../../db/brewing_method.dart';
import '../../db/db_helper.dart';

class BrewingMethodProvider extends ChangeNotifier {
  final DBHelper dbHelper;

  List<BrewingMethod> _methods = [];
  bool _isLoaded = false;

  BrewingMethodProvider({required this.dbHelper}) {
    _loadBrewingMethods();
  }

  Future<void> _loadBrewingMethods() async {
    if (_isLoaded) return;
    try {
      _methods = await dbHelper.getBrewingMethods();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading brewing methods: $e');
    }
  }

  List<BrewingMethod> getAllMethods() => _methods;

  BrewingMethod? getMethodById(int id) =>
      _methods.firstWhereOrNull((m) => m.id == id);

  String getLocalizedSizeName(BuildContext context, int id) {
    final method = _methods.firstWhere(
      (m) => m.id == id,
    );

    return DBHelper.getLocalizedBrewingMethod(method.code, context);
  }
}
