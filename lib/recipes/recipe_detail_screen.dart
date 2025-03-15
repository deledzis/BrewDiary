import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../db/db_helper.dart';
import 'add_edit_recipe_screen.dart';
import 'brew_guide_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  Widget _buildRunInstructionsButtonWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.play_arrow),
      tooltip: l10n.startBrewing,
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
            SnackBar(
              content: Text(l10n.noInstructionsForRecipe),
            ),
          );
        }
      },
    );
  }

  Widget _buildShareButtonWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: l10n.shareRecipe,
      onPressed: () {
        final shareContent = "${l10n.recipe}: ${recipe['name']}\n"
            "${l10n.description}: ${recipe['description'] ?? l10n.notSpecified}\n"
            "${l10n.brewingMethod}: ${_getMethodName(recipe, context)}\n"
            "${l10n.grindSize}: ${_getGrindSizeName(recipe)}\n"
            "${l10n.coffee}: ${recipe['coffee_grams'] ?? l10n.notSpecified} ${l10n.g}\n"
            "${l10n.water}: ${recipe['water_volume'] ?? l10n.notSpecified} ${l10n.ml}\n"
            "${l10n.waterTemperature}: ${recipe['water_temperature'] ?? l10n.notSpecified}°C\n"
            "${l10n.method}: ${recipe['instructions']}";
        Share.share(shareContent, subject: recipe['name']);
      },
    );
  }

  Widget _buildDeleteButtonWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.delete),
      tooltip: l10n.delete,
      onPressed: () => _confirmDelete(context),
    );
  }

  Widget _buildRecipeNameWidget(BuildContext context) {
    return Text(
      recipe['name'],
      style: Theme.of(context).textTheme.headlineMedium,
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
            // Brew Method Section
            FutureBuilder<String>(
              future: _getMethodName(recipe, context),
              builder: (context, snapshot) {
                return _buildDetailRowItem(
                  l10n.brewingMethod,
                  snapshot.connectionState == ConnectionState.waiting
                      ? l10n.loading
                      : snapshot.data ?? l10n.notSpecified,
                  Icons.coffee,
                );
              },
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildDetailRowItem(
                    l10n.coffee,
                    recipe['coffee_grams'] != null
                        ? '${recipe['coffee_grams']} ${l10n.g}'
                        : l10n.notSpecified,
                    Icons.coffee_maker,
                  ),
                ),
                Expanded(
                  child: _buildDetailRowItem(
                    l10n.grindSize,
                    _getGrindSizeName(recipe),
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
                    recipe['water_volume'] != null
                        ? '${recipe['water_volume']} ${l10n.ml}'
                        : l10n.notSpecified,
                    Icons.water_drop,
                  ),
                ),
                Expanded(
                  child: _buildDetailRowItem(
                    l10n.temperature,
                    recipe['water_temperature'] != null
                        ? '${recipe['water_temperature']}${l10n.celsius}'
                        : l10n.notSpecified,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name']),
        actions: [
          _buildRunInstructionsButtonWidget(context),
          _buildShareButtonWidget(context),
          _buildDeleteButtonWidget(context),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Name
            _buildRecipeNameWidget(context),
            const SizedBox(height: 24),
            // Recipe Details Card
            _buildRecipeDetailsCard(context),
            const SizedBox(height: 24),

            // Description Section
            if (recipe['description'] != null &&
                recipe['description'].toString().trim().isNotEmpty) ...[
              Text(
                l10n.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(recipe['description']),
              ),
              const SizedBox(height: 24),
            ],

            // Instructions Section
            Text(
              l10n.method,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(recipe['instructions'] ?? l10n.noInstructions),
            ),

            const SizedBox(height: 24),

            // Brew Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                      SnackBar(
                        content: Text(l10n.noInstructionsForRecipe),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.startBrewingButton),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.edit),
      ),
    );
  }

  String _getGrindSizeName(Map<String, dynamic> recipe) {
    final grindSize = recipe['grind_size'];
    if (grindSize == null) return 'Not specified';

    return DBHelper.GRIND_SIZE_NAMES[grindSize] ?? grindSize;
  }

  Future<String> _getMethodName(
      Map<String, dynamic> recipe, BuildContext context) async {
    final methodId = recipe['method_id'];
    if (methodId == null) return 'Not specified';

    final method = await DBHelper().getMethodById(methodId);
    return method?['name'] ?? 'Unknown method';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRecipe),
        content: Text(
          'Are you sure you want to delete "${recipe['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper().deleteRecipe(recipe['id']);
      Navigator.pop(context, true);
    }
  }
}
