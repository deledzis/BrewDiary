import 'package:brew_diary/db/brewing_result.dart';
import 'package:brew_diary/db/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../db/db_helper.dart';
import '../domain/provider/brewing_methods_provider.dart';
import '../domain/provider/grind_sizes_provider.dart';

class AddEditEntryScreen extends StatefulWidget {
  final BrewingResult? entry;

  const AddEditEntryScreen({super.key, this.entry});

  @override
  State<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final dbHelper = DBHelper();

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

  List<Recipe> _recipes = [];
  int? _selectedRecipeId;
  int? _selectedMethodId;
  int? _selectedGrindSizeId;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing AddEditEntryScreen");

    // Initialize controllers with existing data (for editing) or empty strings (for new entry)
    _coffeeGramsController =
        TextEditingController(text: widget.entry?.coffeeGrams.toString() ?? '');
    _waterVolumeController =
        TextEditingController(text: widget.entry?.waterVolume.toString() ?? '');
    _temperatureController = TextEditingController(
        text: widget.entry?.waterTemperature.toString() ?? '');
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');

    _aroma = widget.entry?.aroma ?? 3.0;
    _acidity = widget.entry?.acidity ?? 3.0;
    _sweetness = widget.entry?.sweetness ?? 3.0;
    _body = widget.entry?.body ?? 3.0;
    _selectedRecipeId = widget.entry?.recipeId;
    _selectedMethodId = widget.entry?.methodId;
    _selectedGrindSizeId = widget.entry?.grindSizeId;

    debugPrint(
        "Initialized with methodId: $_selectedMethodId, grindSizeId: $_selectedGrindSizeId");

    // Load data from the database
    _loadRecipes();
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

  /// Loads recipes from the database and updates the state.
  Future<void> _loadRecipes() async {
    debugPrint("Loading recipes from the database");
    setState(() {
      _isLoading = true;
    });
    final recipes = await dbHelper.getRecipes();
    debugPrint("Number of recipes loaded: ${recipes.length}");

    setState(() {
      _recipes = recipes;
      // If a recipe was previously selected but is not found in the loaded list, reset the selection
      if (_selectedRecipeId != null) {
        final recipeExists =
            _recipes.any((recipe) => recipe.id == _selectedRecipeId);
        if (!recipeExists) {
          _selectedRecipeId = null;
          debugPrint(
              "Previously selected recipe not found, resetting selection");
        }
      }
    });
    setState(() {
      _isLoading = false;
    });
  }

  /// Submits the form data after validation.
  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint("Form validated. Preparing data for saving.");
      debugPrint(
          "Saving methodId: $_selectedMethodId, grindSizeId: $_selectedGrindSizeId");
      final entryData = {
        'id': widget.entry?.id,
        'method_id': _selectedMethodId,
        'coffee_grams': int.tryParse(_coffeeGramsController.text) ?? 0,
        'water_volume': int.tryParse(_waterVolumeController.text) ?? 0,
        'water_temperature': int.tryParse(_temperatureController.text) ?? 0,
        'aroma': _aroma,
        'grind_size_id': _selectedGrindSizeId,
        'acidity': _acidity,
        'sweetness': _sweetness,
        'body': _body,
        'timestamp': DateTime.now().toIso8601String(),
        'recipe_id': _selectedRecipeId,
        'notes': _notesController.text,
        'created_date': DateTime.now().toIso8601String(),
      };
      final brewingResult = BrewingResult.fromMap(entryData);

      if (widget.entry != null) {
        await DBHelper().updateBrewingResult(brewingResult);
        debugPrint("Entry updated with ID: ${widget.entry!.id}");
      } else {
        await dbHelper.insertBrewingResult(brewingResult);
        debugPrint("New entry created");
      }
      if (mounted) {
        Navigator.of(context).pop(entryData);
      }
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
    if (_isLoading) {
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
    final Map<int, Recipe> uniqueRecipes = {};
    for (var recipe in _recipes) {
      final id = recipe.id!;
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
                value: recipe.id,
                child: Text(recipe.name),
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
    final brewingMethodProvider = context.watch<BrewingMethodProvider>();
    final methods = brewingMethodProvider.getAllMethods();

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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: _selectedMethodId,
              hint: Text(l10n.selectMethod),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.notSpecified),
                ),
                ...methods.map((method) {
                  return DropdownMenuItem<int?>(
                    value: method.id,
                    child: Text(DBHelper.getLocalizedBrewingMethod(
                        method.code, context)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMethodId = value;
                });
                debugPrint(
                    "Selected brewing method ID: $value (previous: ${widget.entry?.methodId})");
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the grind size dropdown section.
  Widget _buildGrindSizeSection(AppLocalizations l10n) {
    final grindSizesProvider = context.watch<GrindSizesProvider>();
    final grindSizes = grindSizesProvider.getAllGrindSizes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.grindSize,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: _selectedGrindSizeId,
              hint: Text(l10n.selectGrindSize),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.notSpecified),
                ),
                ...grindSizes.map((grindSize) {
                  return DropdownMenuItem<int?>(
                    value: grindSize.id,
                    child: Text(DBHelper.getLocalizedGrindSize(
                        grindSize.code, context)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGrindSizeId = value;
                });
                debugPrint(
                    "Selected grind size: $value (previous: ${widget.entry?.grindSizeId})");
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
  /// TODO: add link with recipe in this section, when recipe is selected,
  /// prefill values from recipe
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
              _buildGrindSizeSection(l10n),
              const SizedBox(height: 24),
              _buildRecipeSection(context),
              const SizedBox(height: 24),
              _buildBrewingParametersSection(context),
              const SizedBox(height: 24),
              _buildTasteAttributesSection(context),
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
