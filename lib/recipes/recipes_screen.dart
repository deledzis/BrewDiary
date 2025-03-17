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
  final Map<int, String> _methodNames = {};

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final methods = await dbHelper.getBrewingMethods();
    setState(() {
      for (var method in methods) {
        _methodNames[method.id] = method.name;
      }
    });
  }

  Future<void> _loadRecipes() async {
    final recipes = await dbHelper.getRecipes();
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
          methodName = _methodNames[recipe.methodId] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.coffee),
              title: Text(recipe.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe.description.toString().isNotEmpty)
                    Text(
                      recipe.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (methodName.isNotEmpty) Text(methodName),
                  Text('${l10n.coffeeAmount}: ${recipe.coffeeGrams} ${l10n.g}\n'
                      '${l10n.waterAmount}: ${recipe.waterVolume} ${l10n.ml}\n'
                      '${l10n.waterTemperature}: ${recipe.waterTemperature}${l10n.celsius}'),
                ],
              ),
              trailing: recipe.isFavorite == true
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
