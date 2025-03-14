import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import 'add_edit_recipe_screen.dart';
import 'brew_guide_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              if (recipe['instructions'] != null &&
                  recipe['instructions'].toString().trim().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrewGuideScreen(recipe: recipe),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Нет инструкций для данного рецепта'),
                  ),
                );
              }
            },
          ),
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
            const Divider(),
            FutureBuilder<Map<String, dynamic>?>(
              future:
                  recipe['grinderId'] != null
                      ? DBHelper().getGrinderById(recipe['grinderId'])
                      : Future.value(null),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Загрузка кофемолки...');
                } else if (snapshot.hasData && snapshot.data != null) {
                  final grinder = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Кофемолка: ${grinder['name']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text('Настройки: ${grinder['settings']}'),
                    ],
                  );
                } else {
                  return const Text('Кофемолка не выбрана');
                }
              },
            ),
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
