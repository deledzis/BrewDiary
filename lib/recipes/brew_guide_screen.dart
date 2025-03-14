import 'package:flutter/material.dart';

class BrewGuideScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const BrewGuideScreen({super.key, required this.recipe});

  @override
  _BrewGuideScreenState createState() => _BrewGuideScreenState();
}

class _BrewGuideScreenState extends State<BrewGuideScreen> {
  late List<String> steps;
  int currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    steps =
        widget.recipe['instructions']
            .toString()
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();
  }

  void _goToNextStep() {
    if (currentStepIndex < steps.length - 1) {
      setState(() {
        currentStepIndex++;
      });
    }
  }

  void _goToPreviousStep() {
    if (currentStepIndex > 0) {
      setState(() {
        currentStepIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep =
        steps.isNotEmpty ? steps[currentStepIndex] : "Инструкции отсутствуют";

    return Scaffold(
      appBar: AppBar(title: const Text("Пошаговое руководство")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Шаг ${currentStepIndex + 1} из ${steps.length}",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  currentStep,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentStepIndex > 0 ? _goToPreviousStep : null,
                  child: const Text("Назад"),
                ),
                ElevatedButton(
                  onPressed:
                      currentStepIndex < steps.length - 1
                          ? _goToNextStep
                          : null,
                  child: const Text("Далее"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
