import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import 'add_edit_recipe_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Удалить рецепт?'),
                      content: const Text(
                        'Вы уверены, что хотите удалить этот рецепт?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Нет'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Да'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                await DBHelper().deleteRecipe(recipe['id']);
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Название: ${recipe['name']}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Описание: ${recipe['description']}'),
            const SizedBox(height: 8),
            Text('Инструкции: ${recipe['instructions']}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          final updatedRecipe = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditRecipeScreen(recipe: recipe),
            ),
          );
          if (updatedRecipe != null) {
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }
}
