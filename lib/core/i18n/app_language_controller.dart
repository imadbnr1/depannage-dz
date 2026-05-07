import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app’s locale and persists the user’s language choice.
class AppLanguageController extends ChangeNotifier {
  AppLanguageController(this._locale);

  static const _key = 'app_language_code';

  Locale _locale;
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  /// Loads saved language from SharedPreferences, or falls back to French.
  static Future<AppLanguageController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'fr';
    return AppLanguageController(Locale(code));
  }

  /// Changes the language and persists it.
  Future<void> setLanguage(String code) async {
    if (code == _locale.languageCode) return;
    _locale = Locale(code);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  /// Key to force a complete rebuild of the MaterialApp when locale changes.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Key get materialAppKey => _navigatorKey; // A UniqueKey or the navigator key

  @override
  void notifyListeners() {
    // We use a UniqueKey to force the entire MaterialApp to rebuild,
    // so that all localised widgets pick up the new locale.
    super.notifyListeners();
  }
}