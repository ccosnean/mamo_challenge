import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/logging/console_log_sink.dart';
import 'package:payments_app/core/logging/log_sink.dart';
import 'package:payments_app/core/logging/logging.dart';

class _Collect implements LogSink {
  final List<LogEntry> entries = [];

  @override
  void write(LogEntry entry) => entries.add(entry);
}

void main() {
  group('ConsoleLogSink', () {
    test('formats one line: time, level, logger, message', () {
      final lines = <String>[];
      ConsoleLogSink(printer: lines.add).write(
        LogEntry(
          time: DateTime(2026, 9, 28, 12, 4, 33, 120),
          level: Level.INFO,
          logger: 'Repo',
          message: 'PAY-88213 received',
        ),
      );

      expect(lines.single, '12:04:33.120 I Repo  PAY-88213 received');
    });

    test('puts the error on its own line', () {
      final lines = <String>[];
      ConsoleLogSink(printer: lines.add).write(
        LogEntry(
          time: DateTime(2026),
          level: Level.WARNING,
          logger: 'Repo',
          message: 'failed',
          error: 'boom',
        ),
      );

      expect(lines.single, contains(' W '));
      expect(lines.single, endsWith('↳ boom'));
    });
  });

  group('configureLogging', () {
    late _Collect sink;
    final log = Logger('Test');

    setUp(() => sink = _Collect());

    test('redacts before any sink sees an entry', () async {
      configureLogging(level: Level.ALL, sinks: [sink], redact: true);

      log.warning(
        'paid AED 900.00 to AE070331234567890123456',
        Exception('token at_Zk3v9Qm2_x-LpA7rT0yW'),
      );
      await pumpEventQueue();

      final entry = sink.entries.single;
      expect(entry.message, isNot(contains('900')));
      expect(entry.message, isNot(contains('0331234567890')));
      expect(entry.error, isNot(contains('Zk3v9Qm2')));
    });

    test('debug builds pass text through unmasked by default', () async {
      configureLogging(level: Level.ALL, sinks: [sink]);

      log.info('paid AED 900.00');
      await pumpEventQueue();

      expect(sink.entries.single.message, 'paid AED 900.00');
    });

    test('keeps stack traces for severe entries only', () async {
      configureLogging(level: Level.ALL, sinks: [sink]);
      final trace = StackTrace.fromString('#0 main');

      log
        ..warning('warn', null, trace)
        ..severe('boom', null, trace);
      await pumpEventQueue();

      expect(sink.entries[0].stackTrace, isNull);
      expect(sink.entries[1].stackTrace, contains('#0 main'));
    });
  });
}
