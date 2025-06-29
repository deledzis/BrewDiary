import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../../db/db_helper.dart';
import '../../db/grind_size.dart';

class GrindSizesProvider extends ChangeNotifier {
  final DBHelper dbHelper;

  List<GrindSize> _grindSizes = [];
  bool _isLoaded = false;

  GrindSizesProvider({required this.dbHelper}) {
    _loadGrindSizes();
  }

  Future<void> _loadGrindSizes() async {
    if (_isLoaded) return;
    try {
      _grindSizes = await dbHelper.getGrindSizes();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading grind sizes: $e');
    }
  }

  List<GrindSize> getAllGrindSizes() => _grindSizes;

  GrindSize? getGrindSizeById(int id) =>
      _grindSizes.firstWhereOrNull((g) => g.id == id);

  String getLocalizedSizeName(BuildContext context, int grindSizeId) {
    final grindSize = _grindSizes.firstWhere(
      (grindSize) => grindSize.id == grindSizeId,
    );

    return DBHelper.getLocalizedGrindSize(grindSize.code, context);
  }
}
