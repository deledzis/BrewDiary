import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';
import 'add_edit_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Map<String, dynamic>> _recipes = [];
  final Map<int, String> _methodNames = {};

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final methods = await DBHelper().getMethods();
    setState(() {
      for (var method in methods) {
        _methodNames[method['id']] = method['name'];
      }
    });
  }

  Future<void> _loadRecipes() async {
    final recipes = await DBHelper().getRecipes();
    setState(() {
      _recipes = recipes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipes)),
      body: ListView.builder(
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          // Get method name
          String methodName = '';
          if (recipe['method_id'] != null) {
            methodName = _methodNames[recipe['method_id']] ?? '';
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.coffee),
              title: Text(recipe['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe['description'] != null &&
                      recipe['description'].toString().isNotEmpty)
                    Text(
                      recipe['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (methodName.isNotEmpty) Text(methodName),
                  if (recipe['coffee_grams'] != null ||
                      recipe['water_volume'] != null)
                    Text(
                        '${recipe['coffee_grams'] != null ? "${l10n.coffeeAmount}: ${recipe['coffee_grams']} ${l10n.g}" : ""}'
                        '${recipe['coffee_grams'] != null && recipe['water_volume'] != null ? ", " : ""}'
                        '${recipe['water_volume'] != null ? "${l10n.waterAmount}: ${recipe['water_volume']} ${l10n.ml}" : ""}'
                        '${recipe['water_temperature'] != null ? ", ${l10n.temperature}: ${recipe['water_temperature']}°C" : ""}'),
                ],
              ),
              trailing: recipe['is_favorite'] == 1
                  ? const Icon(Icons.favorite, color: Colors.red)
                  : null,
              onTap: () async {
                final shouldReload = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(recipe: recipe),
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
}
