import 'dart:developer' as developer;

class Logger {
  static void info(String message) {
    developer.log(
      message,
      name: 'INFO',
      time: DateTime.now(),
    );
  }

  static void error(String message) {
    developer.log(
      message,
      name: 'ERROR',
      time: DateTime.now(),
      level: 1000,
    );
  }

  static void warning(String message) {
    developer.log(
      message,
      name: 'WARNING',
      time: DateTime.now(),
      level: 500,
    );
  }

  static void debug(String message) {
    developer.log(
      message,
      name: 'DEBUG',
      time: DateTime.now(),
    );
  }
}
