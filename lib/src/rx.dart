import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import 'collection_extensions.dart';

part 'obs.dart';
part 'obs_builder.dart';
part 'computed.dart';
part 'effect.dart';
part 'rx_collections.dart';
part 'rx_stream.dart';

/// A reactive wrapper around a value of type [T].
///
/// Reading [value] inside an [Obs] widget automatically subscribes that
/// widget to changes. Setting [value] notifies all subscribed widgets.
///
/// ```dart
/// final count = 0.obs;
/// count.value++;  // triggers rebuild of any Obs reading it
/// ```
class Rx<T> {
  T _value;
  final Set<VoidCallback> _listeners = {};

  /// Creates a reactive wrapper around [initialValue].
  Rx(T initialValue) : _value = initialValue;

  /// The current value. Reading this inside [Obs] registers a dependency.
  T get value {
    _RxTracker.current?.track(this);
    return _value;
  }

  /// Sets a new value and notifies subscribers if it changed.
  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      _notify();
    }
  }

  void _notify() => _BatchManager._dispatch(_listeners);

  void _addListener(VoidCallback cb) => _listeners.add(cb);
  void _removeListener(VoidCallback cb) => _listeners.remove(cb);

  @override
  String toString() => 'Rx($value)';
}

/// Creates an [Rx] wrapper from any value.
///
/// ```dart
/// final count = 0.obs;
/// final name = 'World'.obs;
/// final visible = true.obs;
/// ```
extension RxExtension<T> on T {
  /// Wraps this value in an [Rx] reactive container.
  Rx<T> get obs => Rx<T>(this);
}

/// Convenience methods on [Rx].
///
/// ```dart
/// final count = 0.obs;
/// count.update((prev) => prev + 1);
///
/// final items = Rx<List<String>>([]);
/// items.update((prev) => [...prev, 'new item']);
/// ```
extension RxUpdateExtension<T> on Rx<T> {
  /// Updates the value by applying [updater] to the current value.
  ///
  /// Equivalent to `rx.value = updater(rx.value)`, but reads the previous
  /// value without registering a tracking dependency.
  void update(T Function(T previous) updater) {
    value = updater(_value);
  }
}

class _RxTracker {
  static _RxTracker? current;
  final Set<Rx> _tracked = {};
  void track(Rx rx) => _tracked.add(rx);
}

class _BatchManager {
  static int _depth = 0;
  static final Set<VoidCallback> _pending = {};

  static void _dispatch(Set<VoidCallback> listeners) {
    if (_depth > 0) {
      _pending.addAll(listeners);
    } else {
      for (final cb in Set.of(listeners)) {
        cb();
      }
    }
  }

  static void _flush() {
    if (--_depth == 0) {
      final callbacks = Set.of(_pending);
      _pending.clear();
      for (final cb in callbacks) {
        cb();
      }
    }
  }
}

/// Defers all [Rx] notifications produced inside [fn] and flushes them
/// together once [fn] returns. Nested calls are safe — the flush happens
/// only when the outermost batch completes.
///
/// ```dart
/// batch(() {
///   _firstName.value = 'Jane';
///   _lastName.value  = 'Doe';
///   _age.value       = 30;
/// }); // one rebuild instead of three
/// ```
void batch(void Function() fn) {
  _BatchManager._depth++;
  try {
    fn();
  } finally {
    _BatchManager._flush();
  }
}

