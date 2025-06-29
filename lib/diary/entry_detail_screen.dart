import 'package:brew_diary/db/brewing_result.dart';
import 'package:brew_diary/db/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';
import 'add_edit_entry_screen.dart';

class EntryDetailsScreen extends StatefulWidget {
  final BrewingResult entry;

  const EntryDetailsScreen({super.key, required this.entry});

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  final dbHelper = DBHelper();
  late BrewingResult entry;
  String _brewingMethodName = '';
  String _grindSizeName = '';

  @override
  void initState() {
    super.initState();
    entry = widget.entry;
    debugPrint("Initializing EntryDetailsScreen");
    _loadBrewingMethodName();
    _loadGrindSizeName();
  }

  /// Loads the brewing method name for the entry.
  Future<void> _loadBrewingMethodName() async {
    if (entry.methodId == null) {
      setState(() {
        _brewingMethodName = AppLocalizations.of(context)!.notSpecified;
      });
      return;
    }

    final method = await dbHelper.getBrewingMethodById(entry.methodId!);
    if (method != null) {
      setState(() {
        _brewingMethodName =
            DBHelper.getLocalizedBrewingMethod(method.code, context);
      });
    } else {
      setState(() {
        _brewingMethodName = AppLocalizations.of(context)!.notSpecified;
      });
    }
  }

  /// Loads the grind size name for the entry.
  Future<void> _loadGrindSizeName() async {
    if (entry.grindSizeId == null) {
      setState(() {
        _grindSizeName = AppLocalizations.of(context)!.notSpecified;
      });
      return;
    }

    final grindSize = await dbHelper.getGrindSizeById(entry.grindSizeId!);
    if (grindSize != null) {
      setState(() {
        _grindSizeName =
            DBHelper.getLocalizedGrindSize(grindSize.code, context);
      });
    } else {
      setState(() {
        _grindSizeName = AppLocalizations.of(context)!.notSpecified;
      });
    }
  }

  /// Gets the localized grind size name for an entry.
  String _getGrindSizeName(BrewingResult entry, BuildContext context) {
    return _grindSizeName;
  }

  Widget _buildRecipeDetailsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRowItem(
              l10n.brewingMethod,
              _brewingMethodName,
              Icons.coffee,
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildDetailRowItem(
                    l10n.coffee,
                    '${entry.coffeeGrams} ${l10n.g}',
                    Icons.coffee_maker,
                  ),
                ),
                Expanded(
                  child: _buildDetailRowItem(
                    l10n.grindSize,
                    _getGrindSizeName(entry, context),
                    Icons.grain,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildDetailRowItem(
                    l10n.water,
                    '${entry.waterVolume} ${l10n.ml}',
                    Icons.water_drop,
                  ),
                ),
                Expanded(
                  child: _buildDetailRowItem(
                    l10n.waterTemperature,
                    '${entry.waterTemperature}${l10n.celsius}',
                    Icons.thermostat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRowItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the detailed view of the entry.
  Widget _buildEntryDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DBHelper();
    return ListView(
      children: [
        const SizedBox(height: 8),
        _buildRecipeDetailsCard(context),
        const Divider(),
        Text('${l10n.aroma}: ${entry.aroma}'),
        Text('${l10n.acidity}: ${entry.acidity}'),
        Text('${l10n.sweetness}: ${entry.sweetness}'),
        Text('${l10n.body}: ${entry.body}'),
        const Divider(),
        if (entry.notes != null && entry.notes.toString().trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${l10n.notes}: ${entry.notes}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        FutureBuilder<Recipe?>(
          future: entry.recipeId != null
              ? dbHelper.getRecipeById(entry.recipeId!)
              : Future.value(null),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(l10n.loadingRecipe);
            } else if (snapshot.hasData && snapshot.data != null) {
              final recipe = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.recipe}: ${recipe.name}'),
                  Text('${l10n.description}: ${recipe.description}'),
                ],
              );
            } else {
              return Text(l10n.noRecipeSelected);
            }
          },
        ),
        const Divider(),
        Text('${l10n.date}: ${entry.timestamp}'),
      ],
    );
  }

  /// Displays a confirmation dialog before deleting the entry.
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    debugPrint("Showing delete confirmation dialog.");
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEntry),
        content: Text(l10n.deleteConfirmation),
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
            child: Text(l10n.yes),
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
      debugPrint("Deleting entry with ID: ${entry.id}");
      await dbHelper.deleteBrewingResult(entry.id!);
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.entryDetails),
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
            if (context.mounted) {
              Navigator.pop(context, true);
            }
          }
        },
      ),
    );
  }
}
