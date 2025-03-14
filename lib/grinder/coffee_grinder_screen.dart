import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';
import 'add_edit_grinder_screen.dart';

class CoffeeGrinderScreen extends StatefulWidget {
  const CoffeeGrinderScreen({super.key});

  @override
  _CoffeeGrinderScreenState createState() => _CoffeeGrinderScreenState();
}

class _CoffeeGrinderScreenState extends State<CoffeeGrinderScreen> {
  List<Map<String, dynamic>> _grinders = [];

  @override
  void initState() {
    super.initState();
    _loadGrinders();
  }

  Future<void> _loadGrinders() async {
    final grinders = await DBHelper().getGrinders();
    setState(() {
      _grinders = grinders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.grinders)),
      body: ListView.builder(
        itemCount: _grinders.length,
        itemBuilder: (context, index) {
          final grinder = _grinders[index];
          return ListTile(
            title: Text(grinder['name']),
            subtitle: Text(grinder['settings'] ?? ''),
            onTap: () async {
              final shouldReload = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditGrinderScreen(grinder: grinder),
                ),
              );
              if (shouldReload == true) {
                _loadGrinders();
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newGrinder = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditGrinderScreen(),
            ),
          );
          if (newGrinder != null) {
            _loadGrinders();
          }
        },
      ),
    );
  }
}
