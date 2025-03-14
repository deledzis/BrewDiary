import 'package:flutter/material.dart';

import '../db/db_helper.dart';

class AddEditGrinderScreen extends StatefulWidget {
  final Map<String, dynamic>? grinder;

  const AddEditGrinderScreen({super.key, this.grinder});

  @override
  _AddEditGrinderScreenState createState() => _AddEditGrinderScreenState();
}

class _AddEditGrinderScreenState extends State<AddEditGrinderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _settingsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.grinder?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.grinder?['description'] ?? '',
    );
    _settingsController = TextEditingController(
      text: widget.grinder?['settings'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final grinderData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'settings': _settingsController.text,
      };

      if (widget.grinder == null) {
        await DBHelper().insertGrinder(grinderData);
      } else {
        grinderData['id'] = widget.grinder!['id'];
        await DBHelper().updateGrinder(grinderData);
      }
      Navigator.pop(context, grinderData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.grinder == null
              ? 'Добавить кофемолку'
              : 'Редактировать кофемолку',
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
                decoration: const InputDecoration(labelText: 'Название'),
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
                controller: _settingsController,
                decoration: const InputDecoration(labelText: 'Настройки'),
                maxLines: 3,
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
