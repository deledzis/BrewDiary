import 'dart:io';

import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../diary/add_entry_screen.dart';
import '../diary/entry_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<Map<String, dynamic>> _brewingResults = [];

  @override
  void initState() {
    super.initState();
    _loadBrewingResults();
  }

  Future<void> _loadBrewingResults() async {
    final results = await DBHelper().getBrewingResults();
    setState(() {
      _brewingResults = results;
    });
  }

  double calculateOverallRating(Map<String, dynamic> entry) {
    double aroma = (entry['aroma'] ?? 0);
    double acidity = (entry['acidity'] ?? 0);
    double sweetness = (entry['sweetness'] ?? 0);
    double body = (entry['body'] ?? 0);
    return (aroma + acidity + sweetness + body) / 4;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дневник заваривания кофе')),
      body: ListView.builder(
        itemCount: _brewingResults.length,
        itemBuilder: (context, index) {
          final result = _brewingResults[index];
          double overall = calculateOverallRating(result);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading:
                  result['imagePath'] != null
                      ? Image.file(
                        File(result['imagePath']),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                      : const Icon(Icons.local_cafe),
              title: Text(result['method']),
              subtitle: FutureBuilder<Map<String, dynamic>?>(
                future:
                    result['recipeId'] != null
                        ? DBHelper().getRecipeById(result['recipeId'])
                        : Future.value(null),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Загрузка рецепта...');
                  } else if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      'Рецепт: ${snapshot.data!['name']}\n'
                      'Кофе: ${result['coffeeGrams']} г, Вода: ${result['waterVolume']} мл, Темп: ${result['temperature']}°C',
                    );
                  } else {
                    return Text(
                      'Кофе: ${result['coffeeGrams']} г, Вода: ${result['waterVolume']} мл, Темп: ${result['temperature']}°C',
                    );
                  }
                },
              ),
              trailing: CircleAvatar(child: Text(overall.toStringAsFixed(1))),
              onTap: () async {
                final shouldReload = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            EntryDetailScreen(entry: _brewingResults[index]),
                  ),
                );
                if (shouldReload == true) {
                  _loadBrewingResults();
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newEntry = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEntryScreen()),
          );
          if (newEntry != null) {
            await DBHelper().insertBrewingResult(newEntry);
            _loadBrewingResults();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
