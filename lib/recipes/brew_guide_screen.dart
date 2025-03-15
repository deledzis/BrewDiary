import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BrewGuideScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const BrewGuideScreen({super.key, required this.recipe});

  @override
  _BrewGuideScreenState createState() => _BrewGuideScreenState();
}

class _BrewGuideScreenState extends State<BrewGuideScreen> {
  late List<String> steps;
  int currentStepIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    steps = widget.recipe['instructions']
        .toString()
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.stepByStepGuide)),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentStepIndex = index;
                });
              },
              itemCount: steps.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.steps} ${index + 1}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(steps[index]),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStepIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(l10n.back),
                  )
                else
                  const SizedBox.shrink(),
                if (currentStepIndex < steps.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(l10n.next),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
