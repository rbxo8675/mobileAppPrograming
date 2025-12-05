import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static void log(String message, {LogLevel level = LogLevel.info}) {
    if (!kDebugMode && level == LogLevel.debug) return;
    
    final timestamp = DateTime.now().toString().substring(11, 19);
    final prefix = _getPrefix(level);
    
    debugPrint('[$timestamp] $prefix $message');
  }
  
  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warning(String message) => log(message, level: LogLevel.warning);
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(message, level: LogLevel.error);
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }
  
  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 DEBUG';
      case LogLevel.info:
        return 'ℹ️  INFO';
      case LogLevel.warning:
        return '⚠️  WARN';
      case LogLevel.error:
        return '❌ ERROR';
    }
  }
}
