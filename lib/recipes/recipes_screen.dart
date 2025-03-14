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

  @override
  void initState() {
    super.initState();
    _loadRecipes();
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
          return ListTile(
            title: Text(recipe['name']),
            subtitle: Text(recipe['description'] ?? ''),
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
