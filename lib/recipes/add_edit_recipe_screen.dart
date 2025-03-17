import 'package:brew_diary/db/brewing_method.dart';
import 'package:brew_diary/db/grind_size.dart';
import 'package:brew_diary/db/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';

class AddEditRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddEditRecipeScreen({super.key, this.recipe});

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final dbHelper = DBHelper();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructionsController;
  late TextEditingController _coffeeGramsController;
  late TextEditingController _waterVolumeController;
  late TextEditingController _waterTemperatureController;

  int? _selectedGrindSizeId;
  int? _selectedMethodId;
  List<BrewingMethod> _brewingMethods = [];
  List<GrindSize> _grindSizes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing AddEditRecipeScreen");
    // Initialize controllers with existing recipe data if available.
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.recipe?.description ?? '');
    _instructionsController =
        TextEditingController(text: widget.recipe?.instructions ?? '');
    _coffeeGramsController = TextEditingController(
        text: widget.recipe?.coffeeGrams.toString() ?? '');
    _waterVolumeController = TextEditingController(
        text: widget.recipe?.waterVolume.toString() ?? '');
    _waterTemperatureController = TextEditingController(
        text: widget.recipe?.waterVolume.toString() ?? '');
    _selectedGrindSizeId = widget.recipe?.grindSizeId;
    _selectedMethodId = widget.recipe?.methodId;
    _loadBrewingMethods();
  }

  /// Loads brewing methods from the database and validates the selected method.
  Future<void> _loadBrewingMethods() async {
    debugPrint("Loading brewing methods from DB");
    setState(() {
      _isLoading = true;
    });
    final methods = await dbHelper.getBrewingMethods();
    setState(() {
      _brewingMethods = methods;
      // Validate if the selected method exists in the loaded methods.
      if (_selectedMethodId != null) {
        final methodExists =
            _brewingMethods.any((method) => method.id == _selectedMethodId);
        if (!methodExists) {
          _selectedMethodId = null;
          debugPrint(
              "Selected method ID not found. Resetting _selectedMethodId.");
        }
      }
      debugPrint("Brewing methods loaded: ${_brewingMethods.length}");
    });
    _loadGrindSizes();
  }

  Future<void> _loadGrindSizes() async {
    debugPrint("Loading grind sizes from DB");
    setState(() {
      _isLoading = true;
    });

    try {
      final grindSizes = await dbHelper.getGrindSizes();
      setState(() {
        _grindSizes = grindSizes;
        debugPrint("Grind sizes loaded: ${_grindSizes.length}");
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      debugPrint('Error loading grind sizes: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _coffeeGramsController.dispose();
    _waterVolumeController.dispose();
    _waterTemperatureController.dispose();
    super.dispose();
  }

  /// Validates the form and submits the recipe data.
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      debugPrint("Form validated. Preparing recipe data for saving.");
      final recipeData = {
        'id': widget.recipe?.id,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'instructions': _instructionsController.text,
        'grind_size_id': _selectedGrindSizeId,
        'method_id': _selectedMethodId,
        'coffee_grams': _coffeeGramsController.text.isNotEmpty
            ? int.parse(_coffeeGramsController.text)
            : null,
        'water_volume': _waterVolumeController.text.isNotEmpty
            ? int.parse(_waterVolumeController.text)
            : null,
        'water_temperature': _waterTemperatureController.text.isNotEmpty
            ? int.parse(_waterTemperatureController.text)
            : null,
        'created_date': DateTime.now().toIso8601String(),
      };
      final recipe = Recipe.fromMap(recipeData);

      if (widget.recipe == null) {
        debugPrint("Inserting new recipe");
        await dbHelper.insertRecipe(recipe);
      } else {
        debugPrint("Updating existing recipe with ID: ${widget.recipe!.id}");
        await dbHelper.updateRecipe(recipe);
      }
      if (mounted) {
        Navigator.pop(context, recipeData);
      }
    } else {
      debugPrint("Form validation failed.");
    }
  }

  /// Builds the recipe name input section.
  Widget _buildRecipeNameSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recipeName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: l10n.enterRecipeName,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? l10n.pleaseEnterName : null,
        ),
      ],
    );
  }

  /// Builds the brewing method dropdown section.
  Widget _buildBrewingMethodSection(AppLocalizations l10n) {
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
          child: _isLoading
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
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedMethodId,
                    hint: Text(l10n.selectMethod),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(l10n.notSpecified),
                      ),
                      ..._brewingMethods.map((method) {
                        return DropdownMenuItem<int>(
                          value: method.id,
                          child: Text(method.name),
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

  /// Builds the grind size dropdown section.
  Widget _buildGrindSizeSection(AppLocalizations l10n) {
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
          child: _isLoading
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
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedGrindSizeId,
                    hint: Text(l10n.selectGrindSize),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(l10n.notSpecified),
                      ),
                      ..._grindSizes.map((grindSize) {
                        return DropdownMenuItem<int>(
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
                      debugPrint("Selected grind size: $value");
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Builds the recipe parameters section (coffee amount and water volume).
  Widget _buildRecipeParametersSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recipeParameters,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Coffee amount input field.
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            // Water volume input field.
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
      ],
    );
  }

  /// Builds the water temperature input section.
  Widget _buildTemperatureSection(AppLocalizations l10n) {
    return Column(
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
            controller: _waterTemperatureController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
              suffixText: l10n.celsius,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the description input section.
  Widget _buildDescriptionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.description,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: l10n.enterRecipeDescription,
          ),
        ),
      ],
    );
  }

  /// Builds the brewing instructions input section.
  Widget _buildInstructionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Instructions",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _instructionsController,
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: l10n.enterBrewingInstructions,
          ),
          validator: (value) => value == null || value.isEmpty
              ? l10n.pleaseEnterInstructions
              : null,
        ),
      ],
    );
  }

  /// Builds the save button.
  Widget _buildSaveButton(AppLocalizations l10n) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? l10n.addRecipe : l10n.editRecipe),
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
              _buildRecipeNameSection(l10n),
              const SizedBox(height: 24),
              _buildBrewingMethodSection(l10n),
              const SizedBox(height: 24),
              _buildGrindSizeSection(l10n),
              const SizedBox(height: 24),
              _buildRecipeParametersSection(l10n),
              const SizedBox(height: 16),
              _buildTemperatureSection(l10n),
              const SizedBox(height: 24),
              _buildDescriptionSection(l10n),
              const SizedBox(height: 24),
              _buildInstructionsSection(l10n),
              const SizedBox(height: 32),
              _buildSaveButton(l10n),
            ],
          ),
        ),
      ),
    );
  }
}
