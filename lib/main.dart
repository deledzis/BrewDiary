import 'dart:io';

import 'package:brew_diary/domain/repository/grinders_repository.dart';
import 'package:brew_diary/settings/language_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db/db_helper.dart';
import 'domain/provider/brewing_methods_provider.dart';
import 'domain/provider/grind_sizes_provider.dart';
import 'main_screen.dart';
import 'settings/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DB init for desktop platform
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dbHelper = DBHelper();
  final prefs = await SharedPreferences.getInstance();
  runApp(BrewDiaryApp(prefs: prefs, dbHelper: dbHelper));
}

class BrewDiaryApp extends StatelessWidget {
  final SharedPreferences prefs;
  final DBHelper dbHelper;

  const BrewDiaryApp({super.key, required this.prefs, required this.dbHelper});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(prefs),
        ),
        ChangeNotifierProvider<BrewingMethodProvider>(
          create: (_) => BrewingMethodProvider(dbHelper: dbHelper),
        ),
        ChangeNotifierProvider<GrindSizesProvider>(
          create: (_) => GrindSizesProvider(dbHelper: dbHelper),
        ),
        Provider<GrindersRepository>(
          create: (_) => GrindersRepository(dbHelper: dbHelper),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            locale: languageProvider.languageCode == 'system'
                ? null
                : Locale(languageProvider.languageCode),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ru'), // Russian
            ],
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
