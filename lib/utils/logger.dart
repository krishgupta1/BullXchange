import 'package:flutter/foundation.dart';

/// Simple application logger.
///
/// - `AppLog.verbose` controls whether debug/info logs are emitted (defaults to kDebugMode).
/// - Errors are always forwarded so you can see access-token / API-limit failures.
class AppLog {
  /// When true, emits debug/info logs. Set to `false` to suppress noisy debug/info logs.
  ///
  /// NOTE: changed to `false` to show only critical logs by default as requested.
  static bool verbose = false;

  /// If true, errors are printed in release builds as well. Use with caution.
  static bool showErrorsInRelease = true;

  static void d(Object? message) {
    if (verbose) {
      debugPrint('DEBUG: $message');
    }
  }

  static void i(Object? message) {
    if (verbose) {
      debugPrint('INFO: $message');
    }
  }

  static void w(Object? message) {
    if (verbose) {
      debugPrint('WARN: $message');
    }
  }

  static void e(Object? message) {
    if (kDebugMode) {
      debugPrint('ERROR: $message');
    } else if (showErrorsInRelease) {
      // Use print in release so it still appears in the console/hosting environment.
      // Be careful not to log sensitive secrets in production.
      // This behavior is intentional because you asked to keep logs for token/API issues.
      // Consider disabling showErrorsInRelease for production builds.
      // ignore: avoid_print
      print('ERROR: $message');
    }
  }
}
