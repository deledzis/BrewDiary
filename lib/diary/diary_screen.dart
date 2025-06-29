import 'package:brew_diary/db/brewing_method.dart';
import 'package:brew_diary/db/brewing_result.dart';
import 'package:brew_diary/db/recipe.dart';
import 'package:brew_diary/diary/entry_detail_screen.dart';
import 'package:brew_diary/domain/provider/grind_sizes_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../db/grind_size.dart';
import '../domain/provider/brewing_methods_provider.dart';
import 'add_edit_entry_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final dbHelper = DBHelper();

  List<BrewingResult> _brewingResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("DiaryScreen: initState called");
    _loadBrewingResults();
  }

  /// Loads the brewing results (diary entries) from the database.
  Future<void> _loadBrewingResults() async {
    debugPrint("Loading brewing results from DB");
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await dbHelper.getBrewingResults();
      debugPrint("Loaded ${results.length} brewing results");
      setState(() {
        _brewingResults = results;
      });
    } catch (e) {
      debugPrint('Error loading brewing results: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  /// Calculates the overall rating from taste attributes.
  double calculateOverallRating(BrewingResult entry) {
    double aroma = (entry.aroma);
    double acidity = (entry.acidity);
    double sweetness = (entry.sweetness);
    double body = (entry.body);
    return (aroma + acidity + sweetness + body) / 4;
  }

  /// Gets the localized grind size name for a brewing result.
  String _getGrindSizeName(
      BrewingResult result, List<GrindSize> grindSizes, BuildContext context) {
    if (result.grindSizeId == null) {
      return AppLocalizations.of(context)!.notSpecified;
    }
    final grindSize =
        grindSizes.firstWhereOrNull((g) => g.id == result.grindSizeId);
    if (grindSize == null) {
      return AppLocalizations.of(context)!.notSpecified;
    }
    return DBHelper.getLocalizedGrindSize(grindSize.code, context);
  }

  /// Builds the loading content widget.
  Widget _buildLoadingContent(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.loadingEntries),
        ],
      ),
    );
  }

  /// Builds the empty content widget when there are no diary entries.
  Widget _buildEmptyContent(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 100, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noEntries, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                debugPrint("Navigating to AddEditEntryScreen from empty view");
                final newEntry = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditEntryScreen(),
                  ),
                );
                if (newEntry != null) {
                  debugPrint("New entry received from AddEditEntryScreen");
                  _loadBrewingResults();
                }
              },
              child: Text(l10n.addEntry),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRowItem(String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBrewingResultSubtitle(
    BuildContext context,
    List<GrindSize> grindSizes,
    BrewingResult result,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Recipe?>(
      future: result.recipeId != null
          ? dbHelper.getRecipeById(result.recipeId!)
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(l10n.loadingRecipe);
        }

        final recipe = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe != null) ...[
              _buildPreviewRowItem(
                recipe.name,
                Icons.receipt_long,
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildPreviewRowItem(
                    '${result.coffeeGrams} ${l10n.g}',
                    Icons.coffee_maker,
                  ),
                ),
                Expanded(
                  child: _buildPreviewRowItem(
                    _getGrindSizeName(result, grindSizes, context),
                    Icons.grain,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildPreviewRowItem(
                    '${result.waterVolume} ${l10n.ml}',
                    Icons.water_drop,
                  ),
                ),
                Expanded(
                  child: _buildPreviewRowItem(
                    '${result.waterTemperature}${l10n.celsius}',
                    Icons.thermostat,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Builds a card widget representing a single brewing result.
  Widget _buildBrewingResultCard(
    BrewingResult result,
    List<GrindSize> grindSizes,
    List<BrewingMethod> methods,
    AppLocalizations l10n,
  ) {
    double overall = calculateOverallRating(result);

    // Determine method name based on the available fields.
    String methodName = '';
    if (result.methodId != null) {
      final method = methods.firstWhereOrNull((m) => m.id == result.methodId);
      if (method != null) {
        methodName = DBHelper.getLocalizedBrewingMethod(method.code, context);
      } else {
        methodName = l10n.brewingMethod;
      }
    } else {
      methodName = l10n.notSpecified;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(methodName),
        subtitle: _buildBrewingResultSubtitle(context, grindSizes, result),
        trailing: CircleAvatar(
          child: Text(overall.toStringAsFixed(1)),
        ),
        onTap: () async {
          debugPrint("Tapped diary entry card with ID: ${result.id}");
          final shouldReload = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntryDetailsScreen(entry: result),
            ),
          );
          if (shouldReload == true) {
            debugPrint("Reloading brewing results after detail view");
            _loadBrewingResults();
          }
        },
      ),
    );
  }

  /// Builds the list view of brewing results.
  Widget _buildBrewingResultsList(
    AppLocalizations l10n,
    List<GrindSize> grindSizes,
    List<BrewingMethod> methods,
  ) {
    return ListView.builder(
      itemCount: _brewingResults.length,
      itemBuilder: (context, index) {
        final result = _brewingResults[index];
        return _buildBrewingResultCard(result, grindSizes, methods, l10n);
      },
    );
  }

  /// Builds the floating action button for adding a new entry.
  Widget? _buildFloatingActionButton(AppLocalizations l10n) {
    // Only show the FAB if there are existing entries and the list is not loading.
    if (_isLoading || _brewingResults.isEmpty) {
      return null;
    }
    return FloatingActionButton(
      onPressed: () async {
        debugPrint("Navigating to AddEditEntryScreen from FAB");
        final newEntry = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditEntryScreen(),
          ),
        );
        if (newEntry != null) {
          debugPrint("New entry received from AddEditEntryScreen via FAB");
          _loadBrewingResults();
        }
      },
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brewingMethodProvider = context.watch<BrewingMethodProvider>();
    final grindSizesProvider = context.watch<GrindSizesProvider>();
    final grindSizes = grindSizesProvider.getAllGrindSizes();
    final methods = brewingMethodProvider.getAllMethods();
    Widget bodyContent;

    // Determine body content based on loading state and existing entries.
    if (_isLoading) {
      bodyContent = _buildLoadingContent(l10n);
    } else if (_brewingResults.isEmpty) {
      bodyContent = _buildEmptyContent(l10n);
    } else {
      bodyContent = _buildBrewingResultsList(l10n, grindSizes, methods);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coffeeBrewingDiary)),
      body: bodyContent,
      floatingActionButton: _buildFloatingActionButton(l10n),
    );
  }
}
