// Kotlin-inspired extension methods that complement `package:collection`.
//
// Methods already provided by `package:collection` are not re-defined here
// — they are available automatically once `navhost_state` is imported.
// This file adds only what collection is missing.
//
// Works on plain Dart collections independently of the reactive system.

import 'package:collection/collection.dart';

// ─── Iterable<E> ────────────────────────────────────────────────────────────

extension IterableExtensions<E> on Iterable<E> {
  // ── Aliases for collection methods with less ergonomic names ────────────

  /// First element matching [test], or `null`. Alias for [singleWhereOrNull].
  E? singleOrNull(bool Function(E) test) => singleWhereOrNull(test);

  /// Elements that do NOT match [test]. Alias for [whereNot].
  Iterable<E> filterNot(bool Function(E) test) => whereNot(test);

  /// Groups elements into lists by the key returned by [selector].
  /// Alias for [groupListsBy].
  Map<K, List<E>> groupBy<K>(K Function(E) selector) => groupListsBy(selector);

  /// Splits into successive non-overlapping sublists of [size].
  /// Alias for [slices], returning a [List].
  List<List<E>> chunked(int size) => slices(size).toList();

  // ── New methods not in collection ────────────────────────────────────────

  /// Number of elements matching [test], or total length when [test] is omitted.
  int count([bool Function(E)? test]) {
    if (test == null) return length;
    var n = 0;
    for (final e in this) {
      if (test(e)) n++;
    }
    return n;
  }

  /// Sum of [selector] applied to each element.
  num sumOf(num Function(E) selector) {
    num total = 0;
    for (final e in this) {
      total += selector(e);
    }
    return total;
  }

  /// Element whose [selector] value is the smallest, or `null` if empty.
  E? minByOrNull<C extends Comparable<dynamic>>(C Function(E) selector) {
    E? result;
    C? min;
    for (final e in this) {
      final v = selector(e);
      if (min == null || v.compareTo(min) < 0) {
        result = e;
        min = v;
      }
    }
    return result;
  }

  /// Element whose [selector] value is the largest, or `null` if empty.
  E? maxByOrNull<C extends Comparable<dynamic>>(C Function(E) selector) {
    E? result;
    C? max;
    for (final e in this) {
      final v = selector(e);
      if (max == null || v.compareTo(max) > 0) {
        result = e;
        max = v;
      }
    }
    return result;
  }

  /// Creates a map from elements keyed by [selector].
  Map<K, E> associateBy<K>(K Function(E) selector) =>
      {for (final e in this) selector(e): e};

  /// Creates a map from elements using [transform] to produce each entry.
  Map<K, V> associate<K, V>(MapEntry<K, V> Function(E) transform) =>
      Map.fromEntries(map(transform));

  /// Splits into two lists: elements matching [test] and those that don't.
  (List<E>, List<E>) partition(bool Function(E) test) {
    final yes = <E>[], no = <E>[];
    for (final e in this) {
      (test(e) ? yes : no).add(e);
    }
    return (yes, no);
  }

  /// Removes duplicates by the key returned by [selector], preserving order.
  List<E> distinctBy<K>(K Function(E) selector) {
    final seen = <K>{};
    return [for (final e in this) if (seen.add(selector(e))) e];
  }

  /// Maps each element to an iterable then flattens the results into a [List].
  List<R> flatMap<R>(Iterable<R> Function(E) transform) =>
      [for (final e in this) ...transform(e)];

  /// Pairs elements from `this` and [other], combining them with [transform].
  /// Stops when the shorter iterable is exhausted.
  List<R> zip<R, T>(Iterable<T> other, R Function(E a, T b) transform) {
    final result = <R>[];
    final it = iterator;
    final ot = other.iterator;
    while (it.moveNext() && ot.moveNext()) {
      result.add(transform(it.current, ot.current));
    }
    return result;
  }

  /// Joins elements to a string, optionally transforming each with [transform].
  String joinToString({String separator = ', ', String Function(E)? transform}) =>
      (transform != null ? map(transform) : map((e) => '$e')).join(separator);

  /// Performs [action] on each element and returns the original iterable.
  Iterable<E> onEach(void Function(E) action) {
    for (final e in this) {
      action(e);
    }
    return this;
  }

  /// Alias for [skip].
  Iterable<E> drop(int n) => skip(n);

  /// Alias for [skipWhile].
  Iterable<E> dropWhile(bool Function(E) test) => skipWhile(test);
}

// ─── List<E> ────────────────────────────────────────────────────────────────

extension ListExtensions<E> on List<E> {
  /// Returns a new list sorted descending by [selector].
  /// (Ascending [sortedBy] is provided by `package:collection`.)
  List<E> sortedByDescending<C extends Comparable<dynamic>>(C Function(E) selector) =>
      [...this]..sort((a, b) => selector(b).compareTo(selector(a)));

  /// Valid indices of this list (0..length-1).
  Iterable<int> get indices => Iterable.generate(length);
}

// ─── Map<K, V> ──────────────────────────────────────────────────────────────

// package:collection provides no Map extensions, so all of these are new.

extension MapExtensions<K, V> on Map<K, V> {
  /// Returns a new map with values transformed by [transform].
  Map<K, W> mapValues<W>(W Function(K key, V value) transform) =>
      map((k, v) => MapEntry(k, transform(k, v)));

  /// Returns a new map with keys transformed by [transform].
  Map<J, V> mapKeys<J>(J Function(K key, V value) transform) =>
      {for (final e in entries) transform(e.key, e.value): e.value};

  /// Returns entries where the key matches [test].
  Map<K, V> filterKeys(bool Function(K key) test) =>
      {for (final e in entries) if (test(e.key)) e.key: e.value};

  /// Returns entries where the value matches [test].
  Map<K, V> filterValues(bool Function(V value) test) =>
      {for (final e in entries) if (test(e.value)) e.key: e.value};

  /// Returns entries where both key and value match [test].
  Map<K, V> filter(bool Function(K key, V value) test) =>
      {for (final e in entries) if (test(e.key, e.value)) e.key: e.value};

  /// Returns the value for [key], or [defaultValue] if the key is absent.
  V getOrDefault(K key, V defaultValue) =>
      containsKey(key) ? this[key] as V : defaultValue;

  /// Returns the value for [key], or the result of [orElse] if the key is absent.
  V getOrElse(K key, V Function() orElse) =>
      containsKey(key) ? this[key] as V : orElse();

  /// `true` if no entry matches [test].
  bool none(bool Function(K key, V value) test) =>
      !entries.any((e) => test(e.key, e.value));

  /// `true` if all entries match [test].
  bool all(bool Function(K key, V value) test) =>
      entries.every((e) => test(e.key, e.value));

  /// Number of entries matching [test], or total size when [test] is omitted.
  int count([bool Function(K key, V value)? test]) {
    if (test == null) return length;
    return entries.where((e) => test(e.key, e.value)).length;
  }

  /// Entry whose [selector] value is the smallest, or `null` if empty.
  MapEntry<K, V>? minByOrNull<C extends Comparable<dynamic>>(
      C Function(K key, V value) selector) {
    MapEntry<K, V>? result;
    C? min;
    for (final e in entries) {
      final v = selector(e.key, e.value);
      if (min == null || v.compareTo(min) < 0) {
        result = e;
        min = v;
      }
    }
    return result;
  }

  /// Entry whose [selector] value is the largest, or `null` if empty.
  MapEntry<K, V>? maxByOrNull<C extends Comparable<dynamic>>(
      C Function(K key, V value) selector) {
    MapEntry<K, V>? result;
    C? max;
    for (final e in entries) {
      final v = selector(e.key, e.value);
      if (max == null || v.compareTo(max) > 0) {
        result = e;
        max = v;
      }
    }
    return result;
  }

  /// Converts each entry to [R] using [transform] and returns the list.
  List<R> toList<R>(R Function(K key, V value) transform) =>
      [for (final e in entries) transform(e.key, e.value)];
}
