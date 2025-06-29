import 'package:brew_diary/db/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';
import 'add_edit_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final dbHelper = DBHelper();
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  Map<int?, String> _methodCodes = {};
  Map<int?, String> _grindSizeCodes = {};

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadMethodCodes();
    _loadGrindSizeCodes();
  }

  Future<void> _loadRecipes() async {
    debugPrint("Loading recipes from DB");
    setState(() {
      _isLoading = true;
    });

    try {
      final recipes = await dbHelper.getRecipes();
      setState(() {
        debugPrint("Loaded ${recipes.length} recipes");
        _recipes = recipes;
      });
    } catch (e) {
      debugPrint('Error loading recipes: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMethodCodes() async {
    try {
      final methods = await dbHelper.getBrewingMethods();
      final methodCodes = <int?, String>{};
      for (final method in methods) {
        methodCodes[method.id] = method.code;
      }
      setState(() {
        _methodCodes = methodCodes;
      });
    } catch (e) {
      debugPrint('Error loading method codes: $e');
    }
  }

  Future<void> _loadGrindSizeCodes() async {
    try {
      final grindSizes = await dbHelper.getGrindSizes();
      final grindSizeCodes = <int?, String>{};
      for (final grindSize in grindSizes) {
        grindSizeCodes[grindSize.id] = grindSize.code;
      }
      setState(() {
        _grindSizeCodes = grindSizeCodes;
      });
    } catch (e) {
      debugPrint('Error loading grind size codes: $e');
    }
  }

  /// Gets the localized brewing method name for a recipe.
  String _getBrewingMethodName(Recipe recipe, BuildContext context) {
    if (recipe.methodId == null) {
      return AppLocalizations.of(context)!.notSpecified;
    }
    final methodCode = _methodCodes[recipe.methodId];
    if (methodCode != null) {
      return DBHelper.getLocalizedBrewingMethod(methodCode, context);
    }
    return AppLocalizations.of(context)!.notSpecified;
  }

  /// Gets the localized grind size name for a recipe.
  String _getGrindSizeName(Recipe recipe, BuildContext context) {
    if (recipe.grindSizeId == null) {
      return AppLocalizations.of(context)!.notSpecified;
    }
    final grindSizeCode = _grindSizeCodes[recipe.grindSizeId];
    if (grindSizeCode != null) {
      return DBHelper.getLocalizedGrindSize(grindSizeCode, context);
    }
    return AppLocalizations.of(context)!.notSpecified;
  }

  Widget _buildPreviewRowItem(String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipes)),
      body: _isLoading
          ? Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(l10n.loading),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                // Get method name
                String methodName = '';
                methodName = _getBrewingMethodName(recipe, context);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(recipe.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (methodName.isNotEmpty)
                          Text(
                            methodName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (recipe.description.isNotEmpty)
                          Text(
                            recipe.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPreviewRowItem(
                                '${recipe.coffeeGrams} ${l10n.g}',
                                Icons.coffee_maker,
                              ),
                            ),
                            Expanded(
                              child: _buildPreviewRowItem(
                                _getGrindSizeName(recipe, context),
                                Icons.grain,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPreviewRowItem(
                                '${recipe.waterVolume} ${l10n.ml}',
                                Icons.water_drop,
                              ),
                            ),
                            Expanded(
                              child: _buildPreviewRowItem(
                                '${recipe.waterTemperature}${l10n.celsius}',
                                Icons.thermostat,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: recipe.isFavorite
                              ? const Icon(Icons.favorite, color: Colors.red)
                              : const Icon(Icons.favorite_border),
                          // TODO: replace with start button
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(recipe),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final shouldReload = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                      if (shouldReload == true) {
                        _loadRecipes();
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newRecipe = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditRecipeScreen(),
            ),
          );
          if (newRecipe != null) {
            _loadRecipes();
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(Recipe recipe) async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${recipe.name}?'),
        content: Text(
            'This will permanently delete this grinder and all its settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
