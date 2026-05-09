import 'package:flutter/widgets.dart';

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
      for (final cb in Set.of(_listeners)) {
        cb();
      }
    }
  }

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

class _RxTracker {
  static _RxTracker? current;
  final Set<Rx> _tracked = {};
  void track(Rx rx) => _tracked.add(rx);
}

/// A widget that automatically rebuilds when any [Rx] value read inside
/// its [builder] changes.
///
/// ```dart
/// final count = 0.obs;
///
/// Obs(() => Text('${count.value}'))
/// ```
///
/// Only the [Rx] values accessed during [builder] are tracked — if a value
/// is conditionally read, the subscription updates on each rebuild.
class Obs extends StatefulWidget {
  /// Builder that returns the widget tree. Any [Rx.value] read inside
  /// is automatically tracked.
  final Widget Function() builder;

  /// Creates an [Obs] widget that rebuilds when tracked [Rx] values change.
  const Obs(this.builder, {super.key});

  @override
  State<Obs> createState() => _ObsState();
}

class _ObsState extends State<Obs> {
  Set<Rx> _subscriptions = {};

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    for (final rx in _subscriptions) {
      rx._removeListener(_rebuild);
    }

    final tracker = _RxTracker();
    _RxTracker.current = tracker;
    final result = widget.builder();
    _RxTracker.current = null;

    _subscriptions = tracker._tracked;
    for (final rx in _subscriptions) {
      rx._addListener(_rebuild);
    }

    return result;
  }

  @override
  void dispose() {
    for (final rx in _subscriptions) {
      rx._removeListener(_rebuild);
    }
    super.dispose();
  }
}
