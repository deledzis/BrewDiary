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
      };

      if (widget.recipe == null) {
        // Добавление нового рецепта
        await DBHelper().insertRecipe(recipeData);
      } else {
        // Обновление существующего рецепта
        recipeData['id'] = widget.recipe!['id'];
        await DBHelper().updateRecipe(recipeData);
      }
      Navigator.pop(context, recipeData);
    }
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
