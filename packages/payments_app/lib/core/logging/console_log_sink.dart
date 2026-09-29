import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/logging/log_sink.dart';

/// Writes entries to the debug console as single lines:
///
/// `12:04:33.120 I PaymentsRepository  PAY-88213 approved`
///
/// Errors follow on an indented line; stack traces only for severe entries.
final class ConsoleLogSink implements LogSink {
  ConsoleLogSink({void Function(String line)? printer})
    : _printer = printer ?? debugPrint;

  /// Where lines go. Defaults to `debugPrint`. Swappable for tests.
  final void Function(String line) _printer;

  @override
  void write(LogEntry entry) {
    final buffer = StringBuffer()
      ..write(_timestamp(entry.time))
      ..write(' ${_levelTag(entry.level)} ')
      ..write(entry.logger)
      ..write('  ')
      ..write(entry.message);
    if (entry.error != null) buffer.write('\n  ↳ ${entry.error}');
    if (entry.stackTrace != null) buffer.write('\n${entry.stackTrace}');
    _printer(buffer.toString());
  }

  static String _timestamp(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    final millis = time.millisecond.toString().padLeft(3, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.$millis';
  }

  /// `E`, `W`, `I` or `D`.
  static String _levelTag(Level level) {
    if (level >= Level.SEVERE) return 'E';
    if (level >= Level.WARNING) return 'W';
    if (level >= Level.INFO) return 'I';
    return 'D';
  }
}
