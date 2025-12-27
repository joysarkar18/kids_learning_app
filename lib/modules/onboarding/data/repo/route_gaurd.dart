import 'package:kids_learning/services/locale_service.dart';

class RouteGuard {
  // Check if user needs to select language
  static Future<bool> needsLanguageSelection() async {
    final isSelected = await LocaleService.isLanguageSelected();
    return !isSelected; // Returns true if language is NOT selected
  }

  // Check if language is already selected
  static Future<bool> hasLanguageSelected() async {
    return await LocaleService.isLanguageSelected();
  }
}
