part of 'rx.dart';

// ─── RxList ──────────────────────────────────────────────────────────────────

/// A reactive [List] that notifies subscribers on in-place mutations.
///
/// Mutate via the provided methods — each triggers a reactive rebuild.
/// Read via [value] (unmodifiable view) or the query methods, all of which
/// register a tracking dependency so [Obs] rebuilds when the list changes.
///
/// ```dart
/// final items = RxList<String>();
/// items.add('hello');     // rebuilds any Obs reading this list
/// items.sortedBy((e) => e); // tracked read — returns sorted copy
/// ```
class RxList<E> extends Rx<List<E>> {
  RxList([List<E>? initial]) : super(List<E>.of(initial ?? []));

  // Track + delegate to the underlying List<E> extension methods.
  R _track<R>(R Function(List<E>) fn) {
    _RxTracker.current?.track(this);
    return fn(_value);
  }

  void _trackVoid(void Function(List<E>) fn) {
    _RxTracker.current?.track(this);
    fn(_value);
  }

  // ── Value ──────────────────────────────────────────────────────────────────

  /// Unmodifiable view of the current list. Reading inside [Obs] registers
  /// a dependency.
  @override
  List<E> get value {
    _RxTracker.current?.track(this);
    return List.unmodifiable(_value);
  }

  // ── Mutations (notify on change) ──────────────────────────────────────────

  void add(E element)                     { _value.add(element);         _notify(); }
  void addAll(Iterable<E> elements)       { _value.addAll(elements);     _notify(); }
  void insert(int index, E element)       { _value.insert(index, element); _notify(); }
  void operator []=(int index, E element) { _value[index] = element;     _notify(); }
  E    removeAt(int index)                { final r = _value.removeAt(index); _notify(); return r; }
  void removeWhere(bool Function(E) test) { _value.removeWhere(test);    _notify(); }
  void clear()                            { if (_value.isEmpty) return; _value.clear(); _notify(); }

  bool remove(Object? element) {
    final removed = _value.remove(element);
    if (removed) _notify();
    return removed;
  }

  // ── Indexed access (tracked) ──────────────────────────────────────────────

  E operator [](int index) {
    _RxTracker.current?.track(this);
    return _value[index];
  }

  // ── Properties ────────────────────────────────────────────────────────────

  int              get length    => _track((l) => l.length);
  bool             get isEmpty   => _track((l) => l.isEmpty);
  bool             get isNotEmpty => _track((l) => l.isNotEmpty);
  Iterable<int>    get indices   => _track((l) => l.indices);

  // ── Queries — all tracked, all delegate to collection_extensions ──────────

  // collection provides: firstWhereOrNull, lastWhereOrNull, none, sortedBy,
  // forEachIndexed, mapIndexed, singleWhereOrNull, whereNot, groupListsBy, slices.
  // We delegate to those and expose ergonomic aliases where the names differ.

  E?           firstWhereOrNull(bool Function(E) test)                                    => _track((l) => l.firstWhereOrNull(test));
  E?           lastWhereOrNull(bool Function(E) test)                                     => _track((l) => l.lastWhereOrNull(test));
  E            firstWhere(bool Function(E) test, {E Function()? orElse})                  => _track((l) => l.firstWhere(test, orElse: orElse));
  E?           singleOrNull(bool Function(E) test)                                        => _track((l) => l.singleWhereOrNull(test));
  int          count([bool Function(E)? test])                                            => _track((l) => l.count(test));
  bool         any(bool Function(E) test)                                                 => _track((l) => l.any(test));
  bool         every(bool Function(E) test)                                               => _track((l) => l.every(test));
  bool         none(bool Function(E) test)                                                => _track((l) => l.none(test));
  List<E>      where(bool Function(E) test)                                               => _track((l) => l.where(test).toList());
  List<E>      filterNot(bool Function(E) test)                                           => _track((l) => l.whereNot(test).toList());
  List<R>      map<R>(R Function(E) f)                                                    => _track((l) => l.map(f).toList());
  List<R>      mapIndexed<R>(R Function(int index, E element) f)                         => _track((l) => l.mapIndexed(f).toList());
  void         forEachIndexed(void Function(int index, E element) action)                => _trackVoid((l) => l.forEachIndexed(action));
  num          sumOf(num Function(E) selector)                                            => _track((l) => l.sumOf(selector));
  E?           minByOrNull<C extends Comparable<C>>(C Function(E) selector)              => _track((l) => l.minByOrNull(selector));
  E?           maxByOrNull<C extends Comparable<C>>(C Function(E) selector)              => _track((l) => l.maxByOrNull(selector));
  List<E>      sortedBy<C extends Comparable<C>>(C Function(E) selector)                 => _track((l) => l.sortedBy(selector));
  List<E>      sortedByDescending<C extends Comparable<C>>(C Function(E) selector)       => _track((l) => l.sortedByDescending(selector));
  Map<K, List<E>> groupBy<K>(K Function(E) selector)                                     => _track((l) => l.groupListsBy(selector));
  Map<K, E>    associateBy<K>(K Function(E) selector)                                    => _track((l) => l.associateBy(selector));
  (List<E>, List<E>) partition(bool Function(E) test)                                    => _track((l) => l.partition(test));
  List<E>      distinctBy<K>(K Function(E) selector)                                     => _track((l) => l.distinctBy(selector));
  List<R>      flatMap<R>(Iterable<R> Function(E) transform)                             => _track((l) => l.flatMap(transform));
  List<List<E>> chunked(int size)                                                         => _track((l) => l.slices(size).toList());
  List<R>      zip<R, T>(Iterable<T> other, R Function(E a, T b) transform)              => _track((l) => l.zip(other, transform));
  String       joinToString({String separator = ', ', String Function(E)? transform})    => _track((l) => l.joinToString(separator: separator, transform: transform));
}

// ─── RxMap ───────────────────────────────────────────────────────────────────

/// A reactive [Map] that notifies subscribers on in-place mutations.
///
/// ```dart
/// final scores = RxMap<String, int>();
/// scores['Alice'] = 10;    // rebuilds
/// scores.filterValues((v) => v > 5); // tracked read
/// ```
class RxMap<K, V> extends Rx<Map<K, V>> {
  RxMap([Map<K, V>? initial]) : super(Map<K, V>.of(initial ?? {}));

  R _track<R>(R Function(Map<K, V>) fn) {
    _RxTracker.current?.track(this);
    return fn(_value);
  }

  // ── Value ──────────────────────────────────────────────────────────────────

  @override
  Map<K, V> get value {
    _RxTracker.current?.track(this);
    return Map.unmodifiable(_value);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void operator []=(K key, V value) { _value[key] = value; _notify(); }
  void addAll(Map<K, V> other)      { _value.addAll(other); _notify(); }
  void clear()                      { if (_value.isEmpty) return; _value.clear(); _notify(); }

  V? remove(K key) {
    if (!_value.containsKey(key)) return null;
    final removed = _value.remove(key);
    _notify();
    return removed;
  }

  // ── Indexed access (tracked) ──────────────────────────────────────────────

  V? operator [](K key) {
    _RxTracker.current?.track(this);
    return _value[key];
  }

  // ── Properties ────────────────────────────────────────────────────────────

  int  get length    => _track((m) => m.length);
  bool get isEmpty   => _track((m) => m.isEmpty);
  bool get isNotEmpty => _track((m) => m.isNotEmpty);

  // ── Queries ───────────────────────────────────────────────────────────────

  bool             containsKey(K key)                                                          => _track((m) => m.containsKey(key));
  bool             containsValue(V value)                                                       => _track((m) => m.containsValue(value));
  bool             any(bool Function(K, V) test)                                               => _track((m) => m.entries.any((e) => test(e.key, e.value)));
  bool             none(bool Function(K, V) test)                                              => _track((m) => m.none(test));
  bool             all(bool Function(K, V) test)                                               => _track((m) => m.all(test));
  int              count([bool Function(K, V)? test])                                          => _track((m) => m.count(test));
  V                getOrDefault(K key, V defaultValue)                                         => _track((m) => m.getOrDefault(key, defaultValue));
  V                getOrElse(K key, V Function() orElse)                                       => _track((m) => m.getOrElse(key, orElse));
  Map<K, W>        mapValues<W>(W Function(K, V) transform)                                    => _track((m) => m.mapValues(transform));
  Map<J, V>        mapKeys<J>(J Function(K, V) transform)                                      => _track((m) => m.mapKeys(transform));
  Map<K, V>        filterKeys(bool Function(K) test)                                           => _track((m) => m.filterKeys(test));
  Map<K, V>        filterValues(bool Function(V) test)                                         => _track((m) => m.filterValues(test));
  Map<K, V>        filter(bool Function(K, V) test)                                            => _track((m) => m.filter(test));
  MapEntry<K, V>?  firstWhereOrNull(bool Function(K, V) test)                                 => _track((m) => m.entries.firstWhereOrNull((e) => test(e.key, e.value)));
  MapEntry<K, V>?  minByOrNull<C extends Comparable<C>>(C Function(K, V) selector)            => _track((m) => m.minByOrNull(selector));
  MapEntry<K, V>?  maxByOrNull<C extends Comparable<C>>(C Function(K, V) selector)            => _track((m) => m.maxByOrNull(selector));
  List<R>          toList<R>(R Function(K, V) transform)                                       => _track((m) => m.toList(transform));
}

// ─── RxSet ───────────────────────────────────────────────────────────────────

/// A reactive [Set] that notifies subscribers on in-place mutations.
///
/// ```dart
/// final selected = RxSet<int>();
/// selected.add(1);        // rebuilds
/// selected.none((e) => e > 10); // tracked read
/// ```
class RxSet<E> extends Rx<Set<E>> {
  RxSet([Set<E>? initial]) : super(Set<E>.of(initial ?? {}));

  R _track<R>(R Function(Set<E>) fn) {
    _RxTracker.current?.track(this);
    return fn(_value);
  }

  // ── Value ──────────────────────────────────────────────────────────────────

  @override
  Set<E> get value {
    _RxTracker.current?.track(this);
    return Set.unmodifiable(_value);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  bool add(E element)    { final r = _value.add(element); if (r) _notify(); return r; }
  bool remove(Object? e) { final r = _value.remove(e);   if (r) _notify(); return r; }
  void clear()           { if (_value.isEmpty) return; _value.clear(); _notify(); }

  void addAll(Iterable<E> elements) {
    final before = _value.length;
    _value.addAll(elements);
    if (_value.length != before) _notify();
  }

  void removeWhere(bool Function(E) test) {
    final before = _value.length;
    _value.removeWhere(test);
    if (_value.length != before) _notify();
  }

  // ── Properties ────────────────────────────────────────────────────────────

  int  get length    => _track((s) => s.length);
  bool get isEmpty   => _track((s) => s.isEmpty);
  bool get isNotEmpty => _track((s) => s.isNotEmpty);

  // ── Set operations (return new collections, tracked) ──────────────────────

  Set<E> union(Set<E> other)        => _track((s) => s.union(other));
  Set<E> intersection(Set<E> other) => _track((s) => s.intersection(other));
  Set<E> difference(Set<E> other)   => _track((s) => s.difference(other));
  List<E> toList()                  => _track((s) => s.toList());

  // ── Queries (all tracked, delegate to collection_extensions) ─────────────

  bool         contains(Object? e)                                                          => _track((s) => s.contains(e));
  bool         any(bool Function(E) test)                                                   => _track((s) => s.any(test));
  bool         every(bool Function(E) test)                                                 => _track((s) => s.every(test));
  bool         none(bool Function(E) test)                                                  => _track((s) => s.none(test));
  int          count([bool Function(E)? test])                                              => _track((s) => s.count(test));
  E?           firstWhereOrNull(bool Function(E) test)                                      => _track((s) => s.firstWhereOrNull(test));
  E?           lastWhereOrNull(bool Function(E) test)                                       => _track((s) => s.lastWhereOrNull(test));
  E?           singleOrNull(bool Function(E) test)                                          => _track((s) => s.singleWhereOrNull(test));
  List<E>      where(bool Function(E) test)                                                 => _track((s) => s.where(test).toList());
  List<E>      filterNot(bool Function(E) test)                                             => _track((s) => s.whereNot(test).toList());
  List<R>      map<R>(R Function(E) f)                                                      => _track((s) => s.map(f).toList());
  num          sumOf(num Function(E) selector)                                              => _track((s) => s.sumOf(selector));
  E?           minByOrNull<C extends Comparable<C>>(C Function(E) selector)                => _track((s) => s.minByOrNull(selector));
  E?           maxByOrNull<C extends Comparable<C>>(C Function(E) selector)                => _track((s) => s.maxByOrNull(selector));
  Map<K, List<E>> groupBy<K>(K Function(E) selector)                                       => _track((s) => s.groupListsBy(selector));
  List<R>      flatMap<R>(Iterable<R> Function(E) transform)                               => _track((s) => s.flatMap(transform));
  String       joinToString({String separator = ', ', String Function(E)? transform})      => _track((s) => s.joinToString(separator: separator, transform: transform));
}
