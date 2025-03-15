import 'dart:io';

import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import 'add_edit_entry_screen.dart';

class EntryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    Widget imageSection = const SizedBox.shrink();
    if (entry['imagePath'] != null &&
        (entry['imagePath'] as String).isNotEmpty) {
      imageSection = Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Image.file(
          File(entry['imagePath']),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали записи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить запись?'),
                  content: const Text(
                    'Вы уверены, что хотите удалить эту запись?',
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
                await DBHelper().deleteBrewingResult(entry['id']);
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
            imageSection,
            Text(
              'Метод: ${entry['method']}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Кофе: ${entry['coffeeGrams']} г'),
            Text('Вода: ${entry['waterVolume']} мл'),
            Text('Температура: ${entry['temperature']}°C'),
            const Divider(),
            Text('Аромат: ${entry['aroma']}'),
            Text('Кислотность: ${entry['acidity']}'),
            Text('Сладость: ${entry['sweetness']}'),
            Text('Тело напитка: ${entry['body']}'),
            const Divider(),
            if (entry['notes'] != null &&
                entry['notes'].toString().trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Заметки: ${entry['notes']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            FutureBuilder<Map<String, dynamic>?>(
              future: entry['recipeId'] != null
                  ? DBHelper().getRecipeById(entry['recipeId'])
                  : Future.value(null),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Загрузка рецепта...');
                } else if (snapshot.hasData && snapshot.data != null) {
                  final recipe = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Рецепт: ${recipe['name']}'),
                      Text('Описание: ${recipe['description']}'),
                    ],
                  );
                } else {
                  return const Text('Рецепт не выбран');
                }
              },
            ),
            const Divider(),
            Text('Дата: ${entry['timestamp']}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          final updatedEntry = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditEntryScreen(entry: entry),
            ),
          );
          if (updatedEntry != null) {
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }
}
