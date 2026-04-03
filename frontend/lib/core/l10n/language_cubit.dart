import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('fr'));

  static const supportedLocales = [
    Locale('fr'),
    Locale('ar'),
    Locale('es'),
    Locale('de'),
    Locale('nl'),
    Locale('it'),
  ];

  static const localeNames = {
    'fr': 'Français',
    'ar': 'العربية',
    'es': 'Español',
    'de': 'Deutsch',
    'nl': 'Nederlands',
    'it': 'Italiano',
  };

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code != null) {
      emit(Locale(code));
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
    emit(locale);
  }
}
