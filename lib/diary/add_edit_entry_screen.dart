import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  Widget _buildRecipeDropdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            Text(l10n.loadingRecipe),
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
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(l10n.noRecipeSelected),
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

  Widget _buildImageSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.coverPhoto,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _imagePath != null
            ? Image.file(File(_imagePath!), height: 150)
            : Text(l10n.notSelected),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(l10n.addReplace),
            ),
            const SizedBox(width: 16),
            if (_imagePath != null)
              ElevatedButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete),
                label: Text(l10n.delete),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? l10n.addEntry : l10n.editEntry),
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
              Text(
                l10n.brewingMethod,
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
                  hintText: l10n.enterBrewingMethod,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? l10n.enterBrewingMethod
                    : null,
              ),

              const SizedBox(height: 24),

              // Recipe selection
              Text(
                l10n.linkRecipe,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRecipeDropdown(context),

              const SizedBox(height: 24),

              // Brewing parameters
              Text(
                l10n.brewingParameters,
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
                        Text(
                          l10n.coffee,
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
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: InputBorder.none,
                              suffixText: l10n.g,
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
                        Text(
                          l10n.water,
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
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: InputBorder.none,
                              suffixText: l10n.ml,
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
                  Text(
                    l10n.waterTemperature,
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
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: InputBorder.none,
                        suffixText: l10n.celsius,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Taste attributes section
              Text(
                l10n.tasteCharacteristics,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSlider(
                l10n.aroma,
                _aroma,
                (value) => setState(() => _aroma = value),
              ),
              _buildSlider(
                l10n.acidity,
                _acidity,
                (value) => setState(() => _acidity = value),
              ),
              _buildSlider(
                l10n.sweetness,
                _sweetness,
                (value) => setState(() => _sweetness = value),
              ),
              _buildSlider(
                l10n.body,
                _body,
                (value) => setState(() => _body = value),
              ),

              const SizedBox(height: 24),

              // Image section
              _buildImageSection(context),

              const SizedBox(height: 24),

              // Notes section
              Text(
                l10n.remarks,
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
                  hintText: l10n.enterRemarks,
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
                  child: Text(l10n.save, style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
