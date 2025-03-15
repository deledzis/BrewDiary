import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../db/db_helper.dart';

class AddEditEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? entry;

  const AddEditEntryScreen({super.key, this.entry});

  @override
  _AddEditEntryScreenState createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _methodController;
  late TextEditingController _coffeeGramsController;
  late TextEditingController _waterVolumeController;
  late TextEditingController _temperatureController;
  late TextEditingController _notesController;

  late double _aroma;
  late double _acidity;
  late double _sweetness;
  late double _body;
  bool _isRecipesLoading = true;

  List<Map<String, dynamic>> _recipes = [];
  int? _selectedRecipeId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if editing, or with defaults if adding new
    _methodController =
        TextEditingController(text: widget.entry?['method'] ?? '');
    _coffeeGramsController = TextEditingController(
      text: widget.entry?['coffeeGrams']?.toString() ?? '',
    );
    _waterVolumeController = TextEditingController(
      text: widget.entry?['waterVolume']?.toString() ?? '',
    );
    _temperatureController = TextEditingController(
      text: widget.entry?['temperature']?.toString() ?? '',
    );
    _notesController =
        TextEditingController(text: widget.entry?['notes'] ?? '');

    _aroma = widget.entry?['aroma'] as double? ?? 3.0;
    _acidity = widget.entry?['acidity'] as double? ?? 3.0;
    _sweetness = widget.entry?['sweetness'] as double? ?? 3.0;
    _body = widget.entry?['body'] as double? ?? 3.0;
    _selectedRecipeId = widget.entry?['recipeId'];
    _imagePath = widget.entry?['imagePath'];

    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isRecipesLoading = true;
    });
    final recipes = await DBHelper().getRecipes();

    setState(() {
      _recipes = recipes;

      // Validate if the selected recipe exists in the loaded recipes
      if (_selectedRecipeId != null) {
        final recipeExists =
            _recipes.any((recipe) => recipe['id'] == _selectedRecipeId);
        if (!recipeExists) {
          _selectedRecipeId = null;
        }
      }

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

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final entryData = {
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

      // If editing an existing entry
      if (widget.entry != null) {
        entryData['id'] = widget.entry!['id'];
        await DBHelper().updateBrewingResult(entryData);
      }
      // If adding a new entry - just return data to caller

      Navigator.of(context).pop(entryData);
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
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Загрузка рецептов...'),
          ],
        ),
      );
    }

    // Create a map of unique recipes by ID
    final Map<int, Map<String, dynamic>> uniqueRecipes = {};
    for (var recipe in _recipes) {
      final id = recipe['id'] as int;
      uniqueRecipes[id] = recipe;
    }
    final uniqueRecipesList = uniqueRecipes.values.toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _selectedRecipeId,
          hint: const Text('Выберите рецепт'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Нет рецепта'),
            ),
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
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Изображение записи:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
                onPressed: _removeImage,
                icon: const Icon(Icons.delete),
                label: const Text('Удалить'),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.entry == null ? 'Добавить запись' : 'Редактировать запись'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brewing method
              const Text(
                'Метод заваривания',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _methodController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Введите метод заваривания',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Введите метод заваривания'
                    : null,
              ),

              const SizedBox(height: 24),

              // Recipe selection
              const Text(
                'Связать с рецептом',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRecipeDropdown(),

              const SizedBox(height: 24),

              // Brewing parameters
              const Text(
                'Параметры заваривания',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Coffee amount and water volume
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Кофе',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _coffeeGramsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: InputBorder.none,
                              suffixText: 'г',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Вода',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _waterVolumeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: InputBorder.none,
                              suffixText: 'мл',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Temperature
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Температура воды',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _temperatureController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: InputBorder.none,
                        suffixText: '°C',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Taste attributes section
              const Text(
                'Вкусовые характеристики',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
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

              const SizedBox(height: 24),

              // Image section
              _buildImageSection(),

              const SizedBox(height: 24),

              // Notes section
              const Text(
                'Заметки',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Введите заметки...',
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      const Text('Сохранить', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
