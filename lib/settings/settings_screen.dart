import 'package:brew_diary/settings/statistics_screen.dart';
import 'package:brew_diary/settings/theme_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../grinder/coffee_grinder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Профиль пользователя',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Данные профиля будут добавлены в будущем.'),
            const SizedBox(height: 32),
            ListTile(
              title: Text(l10n.myGrinders),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoffeeGrinderScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.statistics),
              trailing: const Icon(Icons.bar_chart),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.theme),
              trailing: const Icon(Icons.palette),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
