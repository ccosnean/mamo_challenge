import 'package:flutter_test/flutter_test.dart';
import 'package:payments_app/core/async/latest_value.dart';

void main() {
  group('LatestValue', () {
    test('replays the current value to a new listener, then changes', () {
      final value = LatestValue(1)..value = 2;
      addTearDown(value.close);

      expect(value.stream, emitsInOrder([2, 3, 4]));

      value
        ..value = 3
        ..value = 4;
    });

    test('every listener gets the current value independently', () async {
      final value = LatestValue('a');
      addTearDown(value.close);

      expect(await value.stream.first, 'a');
      value.value = 'b';
      expect(await value.stream.first, 'b');
    });
  });
}
