import 'dart:async';

/// A value whose stream replays the current value to each new listener.
final class Latest<T> {
  Latest(this._value);

  T _value;
  final StreamController<T> _changes = StreamController<T>.broadcast();

  T get value => _value;

  set value(T newValue) {
    _value = newValue;
    if (!_changes.isClosed) _changes.add(newValue);
  }

  Stream<T> get stream => Stream<T>.multi((listener) {
    listener.add(_value);
    final subscription = _changes.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  Future<void> close() => _changes.close();
}
