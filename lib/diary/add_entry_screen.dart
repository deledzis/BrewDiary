import 'package:flutter/material.dart';

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

  double _aroma = 3;
  double _acidity = 3;
  double _sweetness = 3;
  double _body = 3;

  @override
  void dispose() {
    _methodController.dispose();
    _coffeeGramsController.dispose();
    _waterVolumeController.dispose();
    _temperatureController.dispose();
    super.dispose();
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
      };

      // Возвращаем данные на предыдущий экран
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
