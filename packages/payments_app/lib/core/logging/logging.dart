import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/logging/log_redactor.dart';
import 'package:payments_app/core/logging/log_sink.dart';

StreamSubscription<LogRecord>? _subscription;

/// Routes every `Logger` in the process to [sinks].
///
/// Sensitive data is masked before any sink sees it, unless [redact] is
/// false. It defaults to masking everywhere except debug builds; profile and
/// release builds (including the hosted demo) are always masked.
///
/// Calling again replaces the previous setup.
void configureLogging({
  required Level level,
  required List<LogSink> sinks,
  bool redact = !kDebugMode,
}) {
  Logger.root.level = level;
  final redactor = redact ? LogRedactor() : null;
  String clean(String text) => redactor?.redact(text) ?? text;

  unawaited(_subscription?.cancel());
  _subscription = Logger.root.onRecord.listen((record) {
    final entry = LogEntry(
      time: record.time,
      level: record.level,
      logger: record.loggerName,
      message: clean(record.message),
      error: record.error == null ? null : clean('${record.error}'),
      stackTrace: record.level >= Level.SEVERE
          ? record.stackTrace?.toString()
          : null,
    );
    for (final sink in sinks) {
      sink.write(entry);
    }
  });
}
