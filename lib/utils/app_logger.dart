import 'package:flutter/foundation.dart';

/// Tagged, release-safe logger for crash triage.
///
/// Every line carries the `[HAFFAR]` prefix so a startup crash can be traced
/// from a phone with:
///
///   adb logcat -c                    # clear old logs
///   adb logcat | findstr HAFFAR      # launch the app, watch live
///
/// Uses [debugPrint] (not `dart:developer log`), because `debugPrint` still
/// reaches logcat in release builds. NEVER log secrets — log hosts, lengths
/// and statuses only.
abstract class AppLog {
  AppLog._();

  static const String tag = '[HAFFAR]';

  static void info(String message) => debugPrint('$tag INFO: $message');

  static void warn(String message) => debugPrint('$tag WARN: $message');

  static void error(String message, [Object? e, StackTrace? st]) {
    debugPrint('$tag ERROR: $message${e == null ? '' : ' | $e'}');
    if (st != null) debugPrint('$tag STACK: $st');
  }
}
