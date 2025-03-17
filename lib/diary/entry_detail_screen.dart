import 'dart:io';

import 'package:brew_diary/db/brewing_result.dart';
import 'package:brew_diary/db/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';
import 'add_edit_entry_screen.dart';

class EntryDetailScreen extends StatelessWidget {
  final BrewingResult entry;

  const EntryDetailScreen({super.key, required this.entry});

  /// Builds the image section if an image path exists.
  Widget _buildImageSection() {
    if (entry.imagePath != null && (entry.imagePath as String).isNotEmpty) {
      debugPrint("Image found. Building image section.");
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Image.file(
          File(entry.imagePath!),
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
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DBHelper();
    return ListView(
      children: [
        _buildImageSection(),
        // TODO: load methods and use name
        Text(
          '${l10n.brewingMethod}: ${entry.methodId}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text('${l10n.coffee}: ${entry.coffeeGrams} ${l10n.g}'),
        Text('${l10n.water}: ${entry.waterVolume} ${l10n.ml}'),
        Text('${l10n.waterTemperature}: ${entry.temperature}${l10n.celsius}'),
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
    final dbHelper = DBHelper();
    final shouldDelete = await _showDeleteConfirmationDialog(context);
    if (shouldDelete) {
      debugPrint("Deleting entry with ID: ${entry.id}");
      await dbHelper.deleteBrewingMethod(entry.id!);
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
