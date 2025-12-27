import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/services/logger_service.dart';

class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();
  static BuildContext? _context;

  factory SnackbarService() {
    return _instance;
  }

  SnackbarService._internal();

  // Initialize with context from your app
  static void initialize(BuildContext context) {
    _context = context;
  }

  void _showSnackbar(String title, String message, ContentType contentType) {
    if (_context == null) {
      debugPrint('SnackbarService not initialized with context');
      return;
    }

    try {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 16),
        padding: EdgeInsets.only(top: 20),
        content: AwesomeSnackbarContent(
          title: title,
          message: message,
          contentType: contentType,
        ),
      );

      ScaffoldMessenger.of(_context!).showSnackBar(snackBar);
    } catch (e) {
      LoggerService.logError('Error showing snackbar: $e');
    }
  }

  void showSuccess({String? title, required String message}) {
    final l10n = AppLocalizations.of(_context!);
    _showSnackbar(title ?? l10n!.success, message, ContentType.success);
  }

  void showError({String? title, required String message}) {
    final l10n = AppLocalizations.of(_context!);
    _showSnackbar(title ?? l10n!.error, message, ContentType.failure);
  }

  void showWarning({String? title, required String message}) {
    final l10n = AppLocalizations.of(_context!);
    _showSnackbar(title ?? l10n!.warning, message, ContentType.warning);
  }

  void showInfo({String? title, required String message}) {
    final l10n = AppLocalizations.of(_context!);
    _showSnackbar(title ?? l10n!.info, message, ContentType.help);
  }
}
