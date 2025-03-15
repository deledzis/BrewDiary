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
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers for input fields
  late TextEditingController _coffeeGramsController;
  late TextEditingController _waterVolumeController;
  late TextEditingController _temperatureController;
  late TextEditingController _notesController;

  // Taste parameters (default value: 3.0)
  double _aroma = 3.0;
  double _acidity = 3.0;
  double _sweetness = 3.0;
  double _body = 3.0;

  // Recipes loading state
  bool _isRecipesLoading = true;
  bool _isMethodsLoading = true;
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _brewingMethods = [];
  int? _selectedRecipeId;
  int? _selectedMethodId;

  // Path for the selected image
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing AddEditEntryScreen");

    // Initialize controllers with existing data (for editing) or empty strings (for new entry)
    _coffeeGramsController = TextEditingController(
        text: widget.entry?['coffeeGrams']?.toString() ?? '');
    _waterVolumeController = TextEditingController(
        text: widget.entry?['waterVolume']?.toString() ?? '');
    _temperatureController = TextEditingController(
        text: widget.entry?['temperature']?.toString() ?? '');
    _notesController =
        TextEditingController(text: widget.entry?['notes'] ?? '');

    // Initialize taste parameters and selected recipe/image if available
    _aroma = widget.entry?['aroma'] as double? ?? 3.0;
    _acidity = widget.entry?['acidity'] as double? ?? 3.0;
    _sweetness = widget.entry?['sweetness'] as double? ?? 3.0;
    _body = widget.entry?['body'] as double? ?? 3.0;
    _selectedRecipeId = widget.entry?['recipeId'];
    _imagePath = widget.entry?['imagePath'];

    // Load data from the database
    _loadRecipes();
    _loadBrewingMethods();
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    _coffeeGramsController.dispose();
    _waterVolumeController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Loads brewing methods from the database and validates the selected method.
  Future<void> _loadBrewingMethods() async {
    debugPrint("Loading brewing methods from DB");
    setState(() {
      _isMethodsLoading = true;
    });
    final methods = await DBHelper().getMethods();
    setState(() {
      _brewingMethods = methods;
      // Validate if the selected method exists in the loaded methods.
      if (_selectedMethodId != null) {
        final methodExists =
            _brewingMethods.any((method) => method['id'] == _selectedMethodId);
        if (!methodExists) {
          _selectedMethodId = null;
          debugPrint(
              "Selected method ID not found. Resetting _selectedMethodId.");
        }
      }
      _isMethodsLoading = false;
      debugPrint("Brewing methods loaded: ${_brewingMethods.length}");
    });
  }

  /// Loads recipes from the database and updates the state.
  Future<void> _loadRecipes() async {
    debugPrint("Loading recipes from the database");
    setState(() {
      _isRecipesLoading = true;
    });
    final recipes = await DBHelper().getRecipes();
    debugPrint("Number of recipes loaded: ${recipes.length}");

    setState(() {
      _recipes = recipes;
      // If a recipe was previously selected but is not found in the loaded list, reset the selection
      if (_selectedRecipeId != null) {
        final recipeExists =
            _recipes.any((recipe) => recipe['id'] == _selectedRecipeId);
        if (!recipeExists) {
          _selectedRecipeId = null;
          debugPrint(
              "Previously selected recipe not found, resetting selection");
        }
      }
      _isRecipesLoading = false;
    });
  }

  /// Picks an image from the gallery.
  Future<void> _pickImage() async {
    debugPrint("Picking image from gallery");
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
      debugPrint("Image selected: ${image.path}");
    } else {
      debugPrint("No image selected");
    }
  }

  /// Removes the selected image.
  void _removeImage() {
    debugPrint("Removing selected image");
    setState(() {
      _imagePath = null;
    });
  }

  /// Submits the form data after validation.
  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint("Form validated. Preparing data for saving.");
      final entryData = {
        'method_id': _selectedMethodId,
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

      // If editing an existing entry, include its ID and update it in the database
      if (widget.entry != null) {
        entryData['id'] = widget.entry!['id'];
        await DBHelper().updateBrewingResult(entryData);
        debugPrint("Entry updated with ID: ${widget.entry!['id']}");
      } else {
        debugPrint("New entry created");
      }
      Navigator.of(context).pop(entryData);
    } else {
      debugPrint("Form validation failed");
    }
  }

  /// Builds a slider widget for configuring taste attributes.
  Widget _buildSlider(
      String label, double currentValue, ValueChanged<double> onChanged) {
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

  /// Builds the recipe dropdown widget.
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
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(l10n.loadingRecipe),
          ],
        ),
      );
    }

    // Creating a unique list of recipes by ID
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
            debugPrint("Recipe selected with ID: $value");
          },
        ),
      ),
    );
  }

  /// Builds the brewing method dropdown section.
  Widget _buildBrewingMethodSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.brewingMethod,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _isMethodsLoading
              ? Container(
                  height: 48,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(l10n.loading),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: _selectedMethodId,
                    hint: Text(l10n.selectMethod),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n.notSpecified),
                      ),
                      ..._brewingMethods.map((method) {
                        return DropdownMenuItem<int?>(
                          value: method['id'] as int,
                          child: Text(method['name']),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMethodId = value;
                      });
                      debugPrint("Selected brewing method ID: $value");
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Section for recipe selection.
  Widget _buildRecipeSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.linkRecipe,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildRecipeDropdown(context),
      ],
    );
  }

  /// Section for brewing parameters input (coffee, water, temperature).
  Widget _buildBrewingParametersSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.brewingParameters,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Input for coffee amount
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.coffee,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
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
                        contentPadding: const EdgeInsets.symmetric(
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
            // Input for water volume
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.water,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
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
                        contentPadding: const EdgeInsets.symmetric(
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
        // Input for water temperature
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.waterTemperature,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: InputBorder.none,
                  suffixText: l10n.celsius,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Section for configuring taste attributes.
  Widget _buildTasteAttributesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tasteCharacteristics,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSlider(
            l10n.aroma, _aroma, (value) => setState(() => _aroma = value)),
        _buildSlider(l10n.acidity, _acidity,
            (value) => setState(() => _acidity = value)),
        _buildSlider(l10n.sweetness, _sweetness,
            (value) => setState(() => _sweetness = value)),
        _buildSlider(
            l10n.body, _body, (value) => setState(() => _body = value)),
      ],
    );
  }

  /// Section for notes input.
  Widget _buildNotesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.remarks,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: l10n.enterRemarks,
          ),
        ),
      ],
    );
  }

  /// Widget for the save button.
  Widget _buildSaveButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(l10n.save, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  /// Section for image selection and display.
  Widget _buildImageSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.coverPhoto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  /// Main build method assembling the widget tree.
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
              _buildBrewingMethodSection(context),
              const SizedBox(height: 24),
              _buildRecipeSection(context),
              const SizedBox(height: 24),
              _buildBrewingParametersSection(context),
              const SizedBox(height: 24),
              _buildTasteAttributesSection(context),
              const SizedBox(height: 24),
              _buildImageSection(context),
              const SizedBox(height: 24),
              _buildNotesSection(context),
              const SizedBox(height: 32),
              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }
}
