// ignore: depend_on_referenced_packages
import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of stack trace methods to display
      errorMethodCount: 5, // Number of methods to display for error logs
      lineLength: 120, // Maximum line length for log output
      colors: true, // Colorize log output
      printEmojis: true, // Print emojis in log
      // Should each log include a timestamp
    ),
  );

  // Static method to log information
  static void logInfo(String message) {
    _logger.i(message);
  }

  // Static method to log warnings
  static void logWarning(String message) {
    _logger.w(message);
  }

  // Static method to log errors
  static void logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.e(message);
  }
}
