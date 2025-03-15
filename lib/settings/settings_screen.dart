import 'package:brew_diary/settings/statistics_screen.dart';
import 'package:brew_diary/settings/theme_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../grinder/my_grinders_screen.dart';
import 'language_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _buildProfileStateWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Имя пользователя',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(l10n.profileData),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Column(
      children: [
        _buildThemeWidget(context),
        const Divider(),
        _buildLanguageWidget(context),
        const Divider(),
        _buildMyGrindersWidget(context),
        const Divider(),
        _buildStatisticsWidget(context),
      ],
    );
  }

  Widget _buildThemeWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
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
    );
  }

  Widget _buildLanguageWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.language),
      trailing: const Icon(Icons.language),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LanguageSettingsScreen(),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
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
    );
  }

  Widget _buildMyGrindersWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.myGrinders),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyGrindersScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileStateWidget(context),
          _buildMenuList(context),
        ],
      ),
    );
  }
}
