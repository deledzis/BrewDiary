import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';
import 'add_edit_entry_screen.dart';
import 'entry_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<Map<String, dynamic>> _brewingResults = [];
  final Map<int, String> _methodNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("DiaryScreen: initState called");
    _loadBrewingResults();
    _loadMethods();
  }

  /// Loads the available brewing methods from the database.
  Future<void> _loadMethods() async {
    debugPrint("Loading brewing methods from DB");
    final methods = await DBHelper().getMethods();
    setState(() {
      for (var method in methods) {
        _methodNames[method['id']] = method['name'];
      }
    });
    debugPrint("Loaded ${_methodNames.length} methods");
  }

  /// Loads the brewing results (diary entries) from the database.
  Future<void> _loadBrewingResults() async {
    debugPrint("Loading brewing results from DB");
    final results = await DBHelper().getBrewingResults();
    setState(() {
      _brewingResults = results;
      _isLoading = false;
    });
    debugPrint("Loaded ${_brewingResults.length} brewing results");
  }

  /// Calculates the overall rating from taste attributes.
  double calculateOverallRating(Map<String, dynamic> entry) {
    double aroma = (entry['aroma'] ?? 0);
    double acidity = (entry['acidity'] ?? 0);
    double sweetness = (entry['sweetness'] ?? 0);
    double body = (entry['body'] ?? 0);
    return (aroma + acidity + sweetness + body) / 4;
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
                  await DBHelper().insertBrewingResult(newEntry);
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

  /// Builds a card widget representing a single brewing result.
  Widget _buildBrewingResultCard(
      Map<String, dynamic> result, AppLocalizations l10n) {
    double overall = calculateOverallRating(result);

    // Determine method name based on the available fields.
    String methodName = '';
    if (result['method_id'] != null) {
      methodName = _methodNames[result['method_id']] ?? l10n.brewingMethod;
    } else if (result['method'] != null) {
      methodName = result['method'];
    } else {
      methodName = l10n.brewingMethod;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: result['imagePath'] != null
            ? Image.file(
                File(result['imagePath']),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.local_cafe),
        title: Text(methodName),
        subtitle: FutureBuilder<Map<String, dynamic>?>(
          future: result['recipeId'] != null
              ? DBHelper().getRecipeById(result['recipeId'])
              : Future.value(null),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(l10n.loadingRecipe);
            } else if (snapshot.hasData && snapshot.data != null) {
              return Text(
                '${l10n.recipe}: ${snapshot.data!['name']}\n'
                '${l10n.coffeeAmount}: ${result['coffeeGrams']} ${l10n.g}, ${l10n.waterAmount}: ${result['waterVolume']} ${l10n.ml}, ${l10n.waterTemperature}: ${result['temperature']}°C',
              );
            } else {
              return Text(
                '${l10n.coffeeAmount}: ${result['coffeeGrams']} ${l10n.g}, ${l10n.waterAmount}: ${result['waterVolume']} ${l10n.ml}, ${l10n.waterTemperature}: ${result['temperature']}°C',
              );
            }
          },
        ),
        trailing: CircleAvatar(child: Text(overall.toStringAsFixed(1))),
        onTap: () async {
          debugPrint("Tapped diary entry card with ID: ${result['id']}");
          final shouldReload = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntryDetailScreen(entry: result),
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
  Widget _buildBrewingResultsList(AppLocalizations l10n) {
    return ListView.builder(
      itemCount: _brewingResults.length,
      itemBuilder: (context, index) {
        final result = _brewingResults[index];
        return _buildBrewingResultCard(result, l10n);
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
          await DBHelper().insertBrewingResult(newEntry);
          _loadBrewingResults();
        }
      },
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget bodyContent;

    // Determine body content based on loading state and existing entries.
    if (_isLoading) {
      bodyContent = _buildLoadingContent(l10n);
    } else if (_brewingResults.isEmpty) {
      bodyContent = _buildEmptyContent(l10n);
    } else {
      bodyContent = _buildBrewingResultsList(l10n);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coffeeBrewingDiary)),
      body: bodyContent,
      floatingActionButton: _buildFloatingActionButton(l10n),
    );
  }
}
