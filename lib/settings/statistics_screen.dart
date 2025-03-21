import 'package:brew_diary/db/brewing_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final dbHelper = DBHelper();
  List<BrewingResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final results = await dbHelper.getBrewingResults();
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  double calculateOverallRating(BrewingResult entry) {
    double aroma = (entry.aroma);
    double acidity = (entry.acidity);
    double sweetness = (entry.sweetness);
    double body = (entry.body);
    return (aroma + acidity + sweetness + body) / 4;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double totalBrews = _results.length.toDouble();
    double averageRating = 0;
    if (_results.isNotEmpty) {
      double sum = 0;
      for (var entry in _results) {
        sum += calculateOverallRating(entry);
      }
      averageRating = sum / _results.length;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.totalEntries}$totalBrews',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.averageRating}${averageRating.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
    );
  }
}
