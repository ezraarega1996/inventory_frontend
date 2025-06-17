import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language';
  final SharedPreferences _prefs;
  Locale _locale;

  LanguageProvider(this._prefs) : _locale = Locale(_prefs.getString(_languageKey) ?? 'en');

  Locale get locale => _locale;

  Future<void> setLanguage(Locale locale) async {
    if (_locale != locale) {
      _locale = locale;
      //await _prefs.setString(_languageKey, locale.languageCode);
      notifyListeners();
    }
  }

  static Future<LanguageProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LanguageProvider(prefs);
  }
} 