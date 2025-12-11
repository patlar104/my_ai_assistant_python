import 'dart:io';
import 'dart:convert';

/// Centralized debug logging utility for comprehensive bug tracking
/// 
/// This utility provides:
/// - Efficient append-only logging (no file reading)
/// - Structured JSON logs with consistent format
/// - Automatic session tracking
/// - User interaction tracking
/// - Error tracking
/// - Performance metrics
class DebugLogger {
  static const String _logPath = r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log';
  static String _sessionId = 'debug-session-${DateTime.now().millisecondsSinceEpoch}';
  static String _runId = 'run1';

  /// Log a user interaction (button click, tap, etc.)
  static void logUserInteraction({
    required String location,
    required String action,
    Map<String, dynamic>? data,
    String? hypothesisId,
  }) {
    _log(
      location: location,
      message: 'User Interaction: $action',
      data: data ?? {},
      hypothesisId: hypothesisId ?? 'UI',
      category: 'user_interaction',
    );
  }

  /// Log an error or exception
  static void logError({
    required String location,
    required String error,
    dynamic originalError,
    Map<String, dynamic>? context,
    String? hypothesisId,
  }) {
    _log(
      location: location,
      message: 'Error: $error',
      data: {
        ...?context,
        'error': error,
        if (originalError != null) 'originalError': originalError.toString(),
      },
      hypothesisId: hypothesisId ?? 'ERROR',
      category: 'error',
    );
  }

  /// Log a state change
  static void logStateChange({
    required String location,
    required String stateName,
    dynamic oldValue,
    dynamic newValue,
    Map<String, dynamic>? additionalData,
    String? hypothesisId,
  }) {
    _log(
      location: location,
      message: 'State Change: $stateName',
      data: {
        ...?additionalData,
        'oldValue': oldValue?.toString(),
        'newValue': newValue?.toString(),
      },
      hypothesisId: hypothesisId ?? 'STATE',
      category: 'state_change',
    );
  }

  /// Log a data flow event (API call, storage, etc.)
  static void logDataFlow({
    required String location,
    required String operation,
    Map<String, dynamic>? data,
    String? hypothesisId,
  }) {
    _log(
      location: location,
      message: 'Data Flow: $operation',
      data: data ?? {},
      hypothesisId: hypothesisId ?? 'DATA',
      category: 'data_flow',
    );
  }

  /// Log a widget build
  static void logWidgetBuild({
    required String location,
    required String widgetName,
    Map<String, dynamic>? data,
    String? hypothesisId,
  }) {
    _log(
      location: location,
      message: 'Widget Build: $widgetName',
      data: data ?? {},
      hypothesisId: hypothesisId ?? 'BUILD',
      category: 'widget_build',
    );
  }

  /// Log a navigation event
  static void logNavigation({
    required String location,
    required String action,
    String? route,
    Map<String, dynamic>? data,
    String? hypothesisId,
  }) {
    _log(
      location: location,
      message: 'Navigation: $action',
      data: {
        ...?data,
        if (route != null) 'route': route,
      },
      hypothesisId: hypothesisId ?? 'NAV',
      category: 'navigation',
    );
  }

  /// Log a dialog/alert interaction
  static void logDialog({
    required String location,
    required String action,
    String? dialogType,
    bool? result,
    Map<String, dynamic>? data,
    String? hypothesisId,
  }) {
    _log(
      location: location,
      message: 'Dialog: $action',
      data: {
        ...?data,
        if (dialogType != null) 'dialogType': dialogType,
        if (result != null) 'result': result,
      },
      hypothesisId: hypothesisId ?? 'DIALOG',
      category: 'dialog',
    );
  }

  /// Log performance metrics
  static void logPerformance({
    required String location,
    required String metric,
    required int durationMs,
    Map<String, dynamic>? additionalData,
    String? hypothesisId,
  }) {
    _log(
      location: location,
      message: 'Performance: $metric',
      data: {
        ...?additionalData,
        'durationMs': durationMs,
      },
      hypothesisId: hypothesisId ?? 'PERF',
      category: 'performance',
    );
  }

  /// Internal logging method - efficient append-only write
  static void _log({
    required String location,
    required String message,
    required Map<String, dynamic> data,
    required String hypothesisId,
    required String category,
  }) {
    try {
      final logFile = File(_logPath);
      final logEntry = jsonEncode({
        'sessionId': _sessionId,
        'runId': _runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'category': category,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Efficient append-only write (no file reading)
      logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (_) {
      // Silently fail - don't break the app if logging fails
    }
  }

  /// Start a new run (call before each test/reproduction)
  static void startNewRun() {
    _runId = 'run-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Start a new session
  static void startNewSession() {
    _sessionId = 'debug-session-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clear the log file
  static void clearLog() {
    try {
      final logFile = File(_logPath);
      if (logFile.existsSync()) {
        logFile.deleteSync();
      }
    } catch (_) {
      // Silently fail
    }
  }
}

