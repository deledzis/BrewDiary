import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import 'edit_entry_screen.dart';

class EntryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали записи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              // Подтверждение удаления
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
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
                // Удаление записи из БД
                await DBHelper().deleteBrewingResult(entry['id']);
                // Закрываем экран, сигнализируя о необходимости обновления списка
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
            Text('Дата: ${entry['timestamp']}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          // Переход к экрану редактирования
          final updatedEntry = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditEntryScreen(entry: entry),
            ),
          );
          // Если запись была изменена – обновляем экран (при необходимости можно передать обновлённые данные назад)
          if (updatedEntry != null) {
            Navigator.pop(context, true);
          }
        },
      ),
    );
  }
}
