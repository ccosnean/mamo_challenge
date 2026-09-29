import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:payments_app/payments_app.dart';

/// Where a log line came from, for filtering.
enum LogSource {
  app('App'),
  http('HTTP'),
  bank('Bank');

  const LogSource(this.label);

  final String label;

  static LogSource of(LogEntry entry) => switch (entry.logger) {
    'MockBank' => bank,
    'Http' => http,
    _ => app,
  };
}

/// The console module: a [LogSink] the app writes into, kept for the
/// Console panel. Holds the latest [_capacity] entries.
///
/// Entries arrive already redacted by the app when redaction is on.
final class ConsoleLog implements LogSink {
  static const int _capacity = 500;

  final ValueNotifier<List<LogEntry>> entries = ValueNotifier(const []);

  final List<LogEntry> _buffer = [];
  bool _flushScheduled = false;

  @override
  void write(LogEntry entry) {
    _buffer.add(entry);
    // Logs can arrive mid-build; publish them after the current frame's
    // work rather than rebuilding the console during someone else's build.
    if (_flushScheduled) return;
    _flushScheduled = true;
    scheduleMicrotask(_flush);
  }

  void clear() {
    _buffer.clear();
    entries.value = const [];
  }

  void _flush() {
    _flushScheduled = false;
    if (_buffer.isEmpty) return;
    final all = [...entries.value, ..._buffer];
    _buffer.clear();
    entries.value = List.unmodifiable(
      all.length > _capacity ? all.sublist(all.length - _capacity) : all,
    );
  }
}
