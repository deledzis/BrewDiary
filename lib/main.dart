import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db/db_helper.dart';
import 'diary/add_entry_screen.dart';
import 'diary/entry_detail_screen.dart';
import 'home/home_screen.dart';

void main() {
  // DB init for desktop platform
  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const BrewDiaryApp());
}

class BrewDiaryApp extends StatelessWidget {
  const BrewDiaryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Journal',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const HomeScreen(),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дневник заваривания кофе')),
      body: ListView.builder(
        itemCount: _brewingResults.length,
        itemBuilder: (context, index) {
          final result = _brewingResults[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(result['method']),
              subtitle: Text(
                'Кофе: ${result['coffeeGrams']} г, Вода: ${result['waterVolume']} мл, Темп: ${result['temperature']}°C',
              ),
              trailing: CircleAvatar(child: Text(result['aroma'].toString())),
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
