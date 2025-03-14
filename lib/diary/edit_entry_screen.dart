import 'package:flutter/material.dart';

import '../db/db_helper.dart';

class EditEntryScreen extends StatefulWidget {
  final Map<String, dynamic> entry;

  const EditEntryScreen({super.key, required this.entry});

  @override
  _EditEntryScreenState createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _methodController;
  late TextEditingController _coffeeGramsController;
  late TextEditingController _waterVolumeController;
  late TextEditingController _temperatureController;

  late double _aroma;
  late double _acidity;
  late double _sweetness;
  late double _body;

  // Список рецептов и выбранный id рецепта
  List<Map<String, dynamic>> _recipes = [];
  int? _selectedRecipeId;

  @override
  void initState() {
    super.initState();
    _methodController = TextEditingController(text: widget.entry['method']);
    _coffeeGramsController = TextEditingController(
      text: widget.entry['coffeeGrams'].toString(),
    );
    _waterVolumeController = TextEditingController(
      text: widget.entry['waterVolume'].toString(),
    );
    _temperatureController = TextEditingController(
      text: widget.entry['temperature'].toString(),
    );

    _aroma = widget.entry['aroma'] as double;
    _acidity = widget.entry['acidity'] as double;
    _sweetness = widget.entry['sweetness'] as double;
    _body = widget.entry['body'] as double;

    // Инициализируем выбранный рецепт, если он уже задан
    _selectedRecipeId = widget.entry['recipeId'];

    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final recipes = await DBHelper().getRecipes();
    setState(() {
      _recipes = recipes;
    });
  }

  @override
  void dispose() {
    _methodController.dispose();
    _coffeeGramsController.dispose();
    _waterVolumeController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedEntry = {
        'id': widget.entry['id'],
        'method': _methodController.text,
        'coffeeGrams': int.tryParse(_coffeeGramsController.text) ?? 0,
        'waterVolume': int.tryParse(_waterVolumeController.text) ?? 0,
        'temperature': int.tryParse(_temperatureController.text) ?? 0,
        'aroma': _aroma,
        'acidity': _acidity,
        'sweetness': _sweetness,
        'body': _body,
        'timestamp': DateTime.now().toIso8601String(),
        'recipeId': _selectedRecipeId,
      };

      await DBHelper().updateBrewingResult(updatedEntry);
      Navigator.of(context).pop(updatedEntry);
    }
  }

  Widget _buildSlider(
    String label,
    double currentValue,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${currentValue.toStringAsFixed(1)}'),
        Slider(
          value: currentValue,
          min: 1,
          max: 5,
          divisions: 4,
          label: currentValue.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRecipeDropdown() {
    return DropdownButtonFormField<int?>(
      decoration: const InputDecoration(
        labelText: 'Связать с рецептом (опционально)',
      ),
      value: _selectedRecipeId,
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Нет рецепта')),
        ..._recipes.map((recipe) {
          return DropdownMenuItem<int?>(
            value: recipe['id'] as int,
            child: Text(recipe['name']),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedRecipeId = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать запись')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _methodController,
                decoration: const InputDecoration(
                  labelText: 'Метод заваривания',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите метод заваривания';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _coffeeGramsController,
                decoration: const InputDecoration(labelText: 'Граммы кофе'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите количество грамм';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _waterVolumeController,
                decoration: const InputDecoration(labelText: 'Объём воды (мл)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите объём воды';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _temperatureController,
                decoration: const InputDecoration(
                  labelText: 'Температура воды (°C)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите температуру воды';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSlider(
                'Аромат',
                _aroma,
                (value) => setState(() => _aroma = value),
              ),
              _buildSlider(
                'Кислотность',
                _acidity,
                (value) => setState(() => _acidity = value),
              ),
              _buildSlider(
                'Сладость',
                _sweetness,
                (value) => setState(() => _sweetness = value),
              ),
              _buildSlider(
                'Тело напитка',
                _body,
                (value) => setState(() => _body = value),
              ),
              const SizedBox(height: 20),
              _buildRecipeDropdown(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Сохранить изменения'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
