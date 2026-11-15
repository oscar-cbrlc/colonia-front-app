import 'package:colonia_front_app/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  Locale _locale = const Locale('es');

  Locale get locale => _locale;

  LocaleProvider(this._localStorageService) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final savedCode = await _localStorageService.languageCode;
    if (savedCode != null && (savedCode == 'en' || savedCode == 'es')) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    notifyListeners();
    await _localStorageService.saveLanguageCode(newLocale.languageCode);
  }
}
