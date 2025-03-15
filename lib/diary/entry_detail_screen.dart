import 'dart:io';

import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import 'add_edit_entry_screen.dart';

class EntryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const EntryDetailScreen({super.key, required this.entry});

  /// Builds the image section if an image path exists.
  Widget _buildImageSection() {
    if (entry['imagePath'] != null &&
        (entry['imagePath'] as String).isNotEmpty) {
      debugPrint("Image found. Building image section.");
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Image.file(
          File(entry['imagePath']),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    debugPrint("No image provided. Returning empty widget.");
    return const SizedBox.shrink();
  }

  /// Builds the detailed view of the entry.
  Widget _buildEntryDetails(BuildContext context) {
    return ListView(
      children: [
        _buildImageSection(),
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
    );
  }

  /// Displays a confirmation dialog before deleting the entry.
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    debugPrint("Showing delete confirmation dialog.");
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Вы уверены, что хотите удалить эту запись?'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint("User cancelled deletion.");
              Navigator.pop(context, false);
            },
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () {
              debugPrint("User confirmed deletion.");
              Navigator.pop(context, true);
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  /// Handles the deletion process of the entry.
  Future<void> _handleDelete(BuildContext context) async {
    final shouldDelete = await _showDeleteConfirmationDialog(context);
    if (shouldDelete) {
      debugPrint("Deleting entry with ID: ${entry['id']}");
      await DBHelper().deleteBrewingResult(entry['id']);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали записи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await _handleDelete(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildEntryDetails(context),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          debugPrint("Navigating to AddEditEntryScreen for editing the entry.");
          final updatedEntry = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditEntryScreen(entry: entry),
            ),
          );
          if (updatedEntry != null) {
            debugPrint("Entry updated. Returning to previous screen.");
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }
}
