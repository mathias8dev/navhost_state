part of 'rx.dart';

extension RxStreamExtension<T> on Rx<T> {
  /// Exposes this [Rx] as a single-subscription [Stream] of future changes.
  ///
  /// The stream does NOT emit the current value on listen — use [value]
  /// directly for that. Each subsequent value change is delivered
  /// synchronously to the listener. Cancelling the subscription removes
  /// the listener automatically.
  ///
  /// ```dart
  /// final count = 0.obs;
  /// print(count.value); // 0 — read current value directly
  /// count.toStream().listen(print); // prints 1, 2, ... on each change
  /// count.value = 1; // prints 1
  /// count.value = 2; // prints 2
  /// ```
  Stream<T> toStream() {
    late StreamController<T> controller;
    void onChanged() {
      if (!controller.isClosed) controller.add(_value);
    }

    controller = StreamController<T>(
      onListen: () => _addListener(onChanged),
      onCancel: () => _removeListener(onChanged),
      sync: true,
    );


    return controller.stream;
  }
}

/// Creates an [Rx] that syncs its value from [stream].
///
/// Starts with [initial] and updates whenever [stream] emits. The returned
/// [Rx] holds a reference to the stream subscription — assign it to a field
/// and cancel it when no longer needed to avoid leaks.
///
/// ```dart
/// final rx = fromStream(priceStream, initial: 0.0);
/// Obs(() => Text('${rx.value}'))
/// ```
Rx<T> fromStream<T>(Stream<T> stream, {required T initial}) {
  final rx = Rx<T>(initial);
  stream.listen((v) => rx.value = v);
  return rx;
}
