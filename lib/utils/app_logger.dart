import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String tag, String message, [dynamic data]) {
    if (kDebugMode) {
      if (data != null) {
        debugPrint('[VG_QATC][$tag] $message | $data');
      } else {
        debugPrint('[VG_QATC][$tag] $message');
      }
    }
  }

  static void info(String tag, String message) => log(tag, 'ℹ️ $message');
  static void success(String tag, String message) => log(tag, '✅ $message');
  static void warn(String tag, String message) => log(tag, '⚠️ $message');
  static void error(String tag, String message, [dynamic err]) => log(tag, '❌ $message', err);
}
