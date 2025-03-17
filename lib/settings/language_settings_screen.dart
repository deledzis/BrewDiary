import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'language_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageSettings),
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: Text('System'),
            value: 'system',
            groupValue: languageProvider.languageCode,
            onChanged: (value) {
              if (value != null) {
                languageProvider.setLanguageCode(value);
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: languageProvider.languageCode,
            onChanged: (value) {
              if (value != null) {
                languageProvider.setLanguageCode(value);
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('Русский'),
            value: 'ru',
            groupValue: languageProvider.languageCode,
            onChanged: (value) {
              if (value != null) {
                languageProvider.setLanguageCode(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
