import 'package:flutter/material.dart';
import 'package:kids_learning/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kids_learning/services/logger_service.dart';

class LocaleService {
  static const String _languageKey = 'selected_language';

  // Save language preference
  static Future<void> saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      LoggerService.logInfo('Language saved: $languageCode');
    } catch (e) {
      LoggerService.logError('Error saving language: $e');
    }
  }

  // Get saved language preference
  static Future<String?> getSavedLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      LoggerService.logInfo('Loaded language: ${languageCode ?? 'none'}');
      return languageCode;
    } catch (e) {
      LoggerService.logError('Error loading language: $e');
      return null;
    }
  }

  // Check if language is already selected
  static Future<bool> isLanguageSelected() async {
    final languageCode = await getSavedLanguagePreference();
    return languageCode != null;
  }

  // Change language dynamically and save it
  static Future<void> changeLanguage(
    BuildContext context,
    String languageCode,
  ) async {
    final locale = Locale(languageCode);
    MyApp.of(context).setLocale(locale);
    await saveLanguagePreference(languageCode);
  }

  // Get current locale
  static Locale getCurrentLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }

  // Clear language preference (for testing/logout)
  static Future<void> clearLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
      LoggerService.logInfo('Language preference cleared');
    } catch (e) {
      LoggerService.logError('Error clearing language: $e');
    }
  }
}
