import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../db/db_helper.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  _AddEntryScreenState createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _methodController = TextEditingController();
  final _coffeeGramsController = TextEditingController();
  final _waterVolumeController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  double _aroma = 3;
  double _acidity = 3;
  double _sweetness = 3;
  double _body = 3;
  bool _isRecipesLoading = true;

  List<Map<String, dynamic>> _recipes = [];
  int? _selectedRecipeId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isRecipesLoading = true;
    });
    final recipes = await DBHelper().getRecipes();
    setState(() {
      _recipes = recipes;
      _isRecipesLoading = false;
    });
  }

  @override
  void dispose() {
    _methodController.dispose();
    _coffeeGramsController.dispose();
    _waterVolumeController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newEntry = {
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
        'imagePath': _imagePath,
        'notes': _notesController.text,
      };

      Navigator.of(context).pop(newEntry);
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
    if (_isRecipesLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Связать с рецептом (опционально)',
        ),
        child: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Text('Загрузка рецептов...'),
          ],
        ),
      );
    }

    if (_recipes.isEmpty) {
      return DropdownButtonFormField<int?>(
        decoration: const InputDecoration(
          labelText: 'Связать с рецептом (опционально)',
        ),
        value: _selectedRecipeId,
        items: const [
          DropdownMenuItem<int?>(value: null, child: Text('Нет рецепта')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedRecipeId = value;
          });
        },
      );
    }

    final Map<int, Map<String, dynamic>> uniqueRecipes = {};
    for (var recipe in _recipes) {
      final id = recipe['id'] as int;
      uniqueRecipes[id] = recipe;
    }
    final uniqueRecipesList = uniqueRecipes.values.toList();

    return DropdownButtonFormField<int?>(
      decoration: const InputDecoration(
        labelText: 'Связать с рецептом (опционально)',
      ),
      value: _selectedRecipeId,
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Нет рецепта')),
        ...uniqueRecipesList.map((recipe) {
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Изображение записи:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _imagePath != null
            ? Image.file(File(_imagePath!), height: 150)
            : const Text('Изображение не выбрано'),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Добавить/Заменить'),
            ),
            const SizedBox(width: 16),
            if (_imagePath != null)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _imagePath = null;
                  });
                },
                icon: const Icon(Icons.delete),
                label: const Text('Удалить'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    // Поле для заметок
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Заметки',
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить запись')),
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
              _buildImageSection(),
              const SizedBox(height: 20),
              _buildNotesSection(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
