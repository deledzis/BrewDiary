import 'package:flutter/material.dart';

import '../db/db_helper.dart';

class AddEditRecipeScreen extends StatefulWidget {
  final Map<String, dynamic>? recipe;

  const AddEditRecipeScreen({super.key, this.recipe});

  @override
  _AddEditRecipeScreenState createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructionsController;

  List<Map<String, dynamic>> _grinders = [];
  int? _selectedGrinderId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe?['name'] ?? '');
    _descriptionController = TextEditingController(
      text: widget.recipe?['description'] ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.recipe?['instructions'] ?? '',
    );
    _selectedGrinderId = widget.recipe?['grinderId'];
    _loadGrinders();
  }

  Future<void> _loadGrinders() async {
    final grinders = await DBHelper().getGrinders();
    setState(() {
      _grinders = grinders;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final recipeData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'instructions': _instructionsController.text,
        'grinderId': _selectedGrinderId,
      };

      if (widget.recipe == null) {
        await DBHelper().insertRecipe(recipeData);
      } else {
        recipeData['id'] = widget.recipe!['id'];
        await DBHelper().updateRecipe(recipeData);
      }
      Navigator.pop(context, recipeData);
    }
  }

  Widget _buildGrinderDropdown() {
    return DropdownButtonFormField<int?>(
      decoration: const InputDecoration(labelText: 'Кофемолка (опционально)'),
      value: _selectedGrinderId,
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Нет кофемолки')),
        ..._grinders.map((grinder) {
          return DropdownMenuItem<int?>(
            value: grinder['id'] as int,
            child: Text(grinder['name']),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGrinderId = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe == null ? 'Добавить рецепт' : 'Редактировать рецепт',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название рецепта',
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Введите название'
                            : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(labelText: 'Инструкции'),
                maxLines: 5,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Введите инструкции'
                            : null,
              ),
              const SizedBox(height: 20),
              _buildGrinderDropdown(),
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
