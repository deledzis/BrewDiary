import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode;
  final SharedPreferences prefs;

  LanguageProvider(this.prefs)
      : _languageCode = prefs.getString('language_code') ?? 'system';

  String get languageCode => _languageCode;

  void setLanguageCode(String code) {
    _languageCode = code;
    prefs.setString('language_code', code);
    notifyListeners();
  }
}
