import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// One log line, already redacted when redaction is on. What sinks receive.
@immutable
final class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.logger,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime time;
  final Level level;

  /// The `Logger` name, e.g. `PaymentsRepository` or `Http`.
  final String logger;
  final String message;
  final String? error;

  /// Only for severe entries.
  final String? stackTrace;
}

/// Somewhere log entries go: the console, a crash reporter, or a host's log
/// viewer. Plugged in through `AppConfig.logSinks`.
// An interface on purpose: hosts provide their own implementation.
// ignore: one_member_abstracts
abstract interface class LogSink {
  void write(LogEntry entry);
}
