import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';

class AddEditGrinderScreen extends StatefulWidget {
  final Map<String, dynamic>? grinder;

  const AddEditGrinderScreen({super.key, this.grinder});

  @override
  _AddEditGrinderScreenState createState() => _AddEditGrinderScreenState();
}

class _AddEditGrinderScreenState extends State<AddEditGrinderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  late TextEditingController _nameController;
  late TextEditingController _notesController;

  // Controllers for each grind size
  final Map<String, Map<String, TextEditingController>> _clickControllers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.grinder?['name'] ?? '',
    );
    _notesController = TextEditingController(
      text: widget.grinder?['notes'] ?? '',
    );

    // Initialize click controllers for each grind size
    for (final grindSize in DBHelper.GRIND_SIZES) {
      _clickControllers[grindSize] = {
        'min': TextEditingController(),
        'max': TextEditingController(),
      };
    }

    _loadGrinderClickSettings();
  }

  Future<void> _loadGrinderClickSettings() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.grinder != null) {
      try {
        final settings =
            await DBHelper().getGrinderClickSettings(widget.grinder!['id']);

        // Fill controllers with saved values
        for (final setting in settings) {
          final grindSize = setting['grind_size'] as String?;
          if (grindSize != null && _clickControllers.containsKey(grindSize)) {
            _clickControllers[grindSize]!['min']!.text =
                setting['min_clicks']?.toString() ?? '';
            _clickControllers[grindSize]!['max']!.text =
                setting['max_clicks']?.toString() ?? '';
          }
        }
      } catch (e) {
        // Handle error
        debugPrint('Error loading grinder settings: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();

    // Dispose all click controllers
    for (final controllers in _clickControllers.values) {
      controllers['min']?.dispose();
      controllers['max']?.dispose();
    }

    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final grinderData = {
          'name': _nameController.text,
          'notes': _notesController.text,
        };

        int grinderId;
        if (widget.grinder == null) {
          // Insert new grinder
          grinderId = await DBHelper().insertGrinder(grinderData);
        } else {
          // Update existing grinder
          grinderId = widget.grinder!['id'];
          grinderData['id'] = grinderId.toString();
          await DBHelper().updateGrinder(grinderData);
        }

        // Save all click settings
        for (final entry in _clickControllers.entries) {
          final grindSize = entry.key;
          final controllers = entry.value;

          final minText = controllers['min']?.text ?? '';
          final maxText = controllers['max']?.text ?? '';

          // Skip if both fields are empty
          if (minText.isEmpty && maxText.isEmpty) continue;

          // Parse values (defaulting to 0 if empty)
          final minClicks = minText.isNotEmpty ? int.parse(minText) : 0;
          final maxClicks = maxText.isNotEmpty ? int.parse(maxText) : 0;

          final settingData = {
            'grinder_id': grinderId,
            'grind_size': grindSize,
            'min_clicks': minClicks,
            'max_clicks': maxClicks,
          };

          await DBHelper().saveGrinderClickSetting(settingData);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving grinder: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _searchTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Grinder Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter grinder model',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                // In a real app, this would search a database of templates
                Navigator.pop(context);

                // For demo purposes, just show a preset template for C3 Pro
                if (value.toLowerCase().contains('c3') ||
                    value.toLowerCase().contains('timemore')) {
                  _applyTemplate('Timemore C3 Pro');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No template found for this grinder')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(String templateName) {
    // This would load a template from a database in a real app
    // For demo purposes, we'll use hardcoded values for Timemore C3 Pro
    setState(() {
      _nameController.text = templateName;

      // Set click ranges for each grind size
      final Map<String, Map<String, int>> templateValues = {
        DBHelper.GRIND_TURKISH: {'min': 2, 'max': 5},
        DBHelper.GRIND_EXTRA_FINE: {'min': 5, 'max': 8},
        DBHelper.GRIND_FINE: {'min': 8, 'max': 11},
        DBHelper.GRIND_MEDIUM_FINE: {'min': 11, 'max': 16},
        DBHelper.GRIND_MEDIUM: {'min': 16, 'max': 20},
        DBHelper.GRIND_MEDIUM_COARSE: {'min': 20, 'max': 24},
        DBHelper.GRIND_COARSE: {'min': 24, 'max': 25},
      };

      // Apply template values to controllers
      for (final entry in templateValues.entries) {
        final grindSize = entry.key;
        final values = entry.value;

        if (_clickControllers.containsKey(grindSize)) {
          _clickControllers[grindSize]!['min']!.text = values['min'].toString();
          _clickControllers[grindSize]!['max']!.text = values['max'].toString();
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied template for $templateName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.grinder == null ? l10n.addGrinder : l10n.editGrinder),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchTemplate,
            tooltip: 'Search Grinder Template',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grinder Name Section
                    const Text(
                      'Grinder Name or Brand',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a name'
                          : null,
                    ),

                    const SizedBox(height: 24),

                    // Grind Ranges Section
                    const Text(
                      'Grind Ranges',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grind size settings
                    ...DBHelper.GRIND_SIZES.map((grindSize) {
                      final displayName =
                          DBHelper.GRIND_SIZE_NAMES[grindSize] ?? grindSize;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Min'),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller:
                                          _clickControllers[grindSize]!['min'],
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 12),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Center(child: Text('-')),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Max'),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller:
                                          _clickControllers[grindSize]!['max'],
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 12),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Notes Section
                    Text(
                      l10n.notes,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(l10n.save,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
