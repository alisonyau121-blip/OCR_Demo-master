import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Configure logging for the entire application
void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      final time = record.time.toString().substring(11, 23);
      final level = record.level.name.padRight(7);
      final name = record.loggerName.padRight(20);
      
      debugPrint('[$time] $level $name ${record.message}');
      
      if (record.error != null) {
        debugPrint('  Error: ${record.error}');
      }
      
      if (record.stackTrace != null) {
        debugPrint('  Stack trace:\n${record.stackTrace}');
      }
    }
  });
}

/// Get a logger for a specific component
Logger getLogger(String name) => Logger(name);

