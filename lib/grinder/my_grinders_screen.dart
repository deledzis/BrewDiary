import 'package:brew_diary/db/grinder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';
import 'add_edit_grinder_screen.dart';

class MyGrindersScreen extends StatefulWidget {
  const MyGrindersScreen({super.key});

  @override
  State<MyGrindersScreen> createState() => _MyGrindersScreenState();
}

class _MyGrindersScreenState extends State<MyGrindersScreen> {
  final dbHelper = DBHelper();

  List<Grinder> _grinders = [];
  final Map<int, int> _clickSettingsCount = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrinders();
  }

  Future<void> _loadGrinders() async {
    setState(() {
      _isLoading = true;
    });

    final grinders = await dbHelper.getGrinders();

    // Count click settings for each grinder
    for (var grinder in grinders) {
      final settings = await dbHelper.getGrinderClickSettings(grinder.id!);
      _clickSettingsCount[grinder.id!] = settings.length;
    }

    setState(() {
      _grinders = grinders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.grinders)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grinders.isEmpty
              ? Center(
                  child: Text(l10n.noGrinder),
                )
              : ListView.builder(
                  itemCount: _grinders.length,
                  itemBuilder: (context, index) {
                    final grinder = _grinders[index];
                    final settingsCount = _clickSettingsCount[grinder.id] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.coffee_maker),
                        title: Text(grinder.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (grinder.notes != null &&
                                grinder.notes.toString().isNotEmpty)
                              Text(
                                grinder.notes!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              settingsCount > 0
                                  ? '$settingsCount ${settingsCount > 1 ? "grind sizes" : "grind size"} configured'
                                  : 'No grind settings defined',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditGrinderScreen(
                                      grinder: grinder,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadGrinders();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDelete(grinder),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditGrinderScreen(
                                grinder: grinder,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadGrinders();
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditGrinderScreen(),
            ),
          );
          if (result == true) {
            _loadGrinders();
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(Grinder grinder) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${grinder.name}?'),
        content: Text(
            'This will permanently delete this grinder and all its settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await dbHelper.deleteGrinder(grinder.id!);
      _loadGrinders();
    }
  }
}
