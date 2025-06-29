import 'package:brew_diary/db/grind_size.dart';
import 'package:brew_diary/db/grinder.dart';
import 'package:brew_diary/db/grinder_click_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/db_helper.dart';

class AddEditGrinderScreen extends StatefulWidget {
  final Grinder? grinder;

  const AddEditGrinderScreen({super.key, this.grinder});

  @override
  State<AddEditGrinderScreen> createState() => _AddEditGrinderScreenState();
}

class _AddEditGrinderScreenState extends State<AddEditGrinderScreen> {
  final dbHelper = DBHelper();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<GrindSize> _grindSizes = [];

  late TextEditingController _nameController;
  late TextEditingController _notesController;

  // Controllers for each grind size
  final Map<int, Map<String, TextEditingController>> _clickControllers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.grinder?.name ?? '',
    );
    _notesController = TextEditingController(
      text: widget.grinder?.notes ?? '',
    );

    _loadGrindSizes();
    _loadGrinderClickSettings();
  }

  Future<void> _loadGrindSizes() async {
    try {
      final grindSizes = await dbHelper.getGrindSizes();
      setState(() {
        _grindSizes = grindSizes;
      });

      // Initialize controllers for each grind size
      for (final grindSize in grindSizes) {
        _clickControllers[grindSize.id] = {
          'min': TextEditingController(),
          'max': TextEditingController(),
        };
      }
    } catch (e) {
      debugPrint('Error loading grind sizes: $e');
    }
  }

  Future<void> _loadGrinderClickSettings() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.grinder != null) {
      try {
        final settings =
            await dbHelper.getGrinderClickSettings(widget.grinder!.id!);

        // Fill controllers with saved values
        for (final setting in settings) {
          final grindSizeId = setting.grindSizeId;
          _clickControllers[grindSizeId]!['min']!.text =
              setting.minClicks.toString();
          _clickControllers[grindSizeId]!['max']!.text =
              setting.maxClicks.toString();
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
          'id': widget.grinder?.id,
          'name': _nameController.text,
          'notes': _notesController.text,
        };
        final grinder = Grinder.fromMap(grinderData);

        int grinderId;
        if (widget.grinder == null) {
          // Insert new grinder
          grinderId = await dbHelper.insertGrinder(grinder);
        } else {
          // Update existing grinder
          grinderId = grinder.id!;
          await dbHelper.updateGrinder(grinder);
        }

        // Save all click settings
        for (final entry in _clickControllers.entries) {
          final grindSizeId = entry.key;
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
            'grind_size_id': grindSizeId,
            'min_clicks': minClicks,
            'max_clicks': maxClicks,
          };
          final grinderSettings = GrinderClickSetting.fromMap(settingData);

          await dbHelper.insertOrUpdateGrinderClickSetting(grinderSettings);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e, s) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving grinder: $e')),
          );
        }
        debugPrintStack(stackTrace: s);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
            onPressed: () {
              /* TODO: add search template screen */
            },
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
                    ..._grindSizes.map((grindSize) {
                      final sizeId = grindSize.id;
                      final sizeCode = grindSize.code;
                      final displayName =
                          DBHelper.getLocalizedGrindSize(sizeCode, context);
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
                                          _clickControllers[sizeId]!['min'],
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
                                          _clickControllers[sizeId]!['max'],
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
