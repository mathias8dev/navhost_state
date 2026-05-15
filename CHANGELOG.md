## 0.2.2

- Add explicit dependency on `package:collection` (already a Flutter transitive dep).
- `collection_extensions.dart` now delegates to `package:collection` for methods it already provides (`firstWhereOrNull`, `lastWhereOrNull`, `none`, `sortedBy`, `forEachIndexed`, `mapIndexed`, `singleWhereOrNull`, `whereNot`, `groupListsBy`, `slices`) instead of reimplementing them. Our file now contains only genuinely missing methods plus ergonomic aliases (`singleOrNull`, `filterNot`, `groupBy`, `chunked`) that call the collection equivalents.

## 0.2.1

- Add `collection_extensions.dart` — standalone Kotlin-inspired extension methods on `Iterable<E>`, `List<E>`, `Map<K,V>` exported for use on plain Dart collections too.
  - `Iterable`: `firstWhereOrNull`, `lastWhereOrNull`, `singleOrNull`, `count`, `none`, `filterNot`, `sumOf`, `minByOrNull`, `maxByOrNull`, `groupBy`, `associateBy`, `associate`, `partition`, `distinctBy`, `flatMap`, `mapIndexed`, `forEachIndexed`, `onEach`, `chunked`, `zip`, `joinToString`, `drop`, `dropWhile`
  - `List`: `sortedBy`, `sortedByDescending`, `indices`
  - `Map`: `mapValues`, `mapKeys`, `filterKeys`, `filterValues`, `filter`, `getOrDefault`, `getOrElse`, `none`, `all`, `count`, `minByOrNull`, `maxByOrNull`, `toList`
- `RxList`, `RxMap`, `RxSet` now expose the full collection extension surface — all query methods are tracked, all delegation handled via an internal `_track` helper (one line per method, no duplicated logic).
- `RxList` additions: `singleOrNull`, `count`, `none`, `filterNot`, `mapIndexed`, `forEachIndexed`, `sumOf`, `minByOrNull`, `maxByOrNull`, `sortedBy`, `sortedByDescending`, `groupBy`, `associateBy`, `partition`, `distinctBy`, `flatMap`, `chunked`, `zip`, `joinToString`, `indices`, `removeWhere`, `[]` (tracked read)
- `RxMap` additions: `any`, `none`, `all`, `count`, `getOrDefault`, `getOrElse`, `mapValues`, `mapKeys`, `filterKeys`, `filterValues`, `filter`, `firstWhereOrNull`, `minByOrNull`, `maxByOrNull`, `toList`, `[]` (tracked read), `containsValue`
- `RxSet` additions: `every`, `none`, `count`, `firstWhereOrNull`, `lastWhereOrNull`, `singleOrNull`, `filterNot`, `map`, `sumOf`, `minByOrNull`, `maxByOrNull`, `groupBy`, `flatMap`, `joinToString`, `union`, `intersection`, `difference`, `toList`, `removeWhere`

## 0.2.0

- Add `batch()` — defers all `Rx` notifications produced inside the callback and flushes them together once it returns. Nested batches are safe; the flush happens only when the outermost batch completes.
- Add `computed()` — returns a read-only `Rx<T>` whose value is derived from other `Rx` values and updates automatically when any dependency changes. Throws on direct assignment.
- Add `Effect` / `effect()` — runs a callback immediately and re-runs it whenever any `Rx` value read inside it changes. Returns an `Effect` handle; call `dispose()` to stop tracking.
- Add `RxList<E>` — reactive `List` wrapper that notifies on in-place mutations (`add`, `remove`, `insert`, `clear`, `[]=`). `value` returns an unmodifiable view.
- Add `RxMap<K, V>` — reactive `Map` wrapper that notifies on in-place mutations (`[]=`, `remove`, `addAll`, `clear`). `value` returns an unmodifiable view.
- Add `RxSet<E>` — reactive `Set` wrapper that notifies on in-place mutations (`add`, `remove`, `addAll`, `clear`). `value` returns an unmodifiable view.
- Add `Rx.toStream()` — exposes an `Rx` as a single-subscription `Stream` of future changes (does not emit the current value on listen). Delivery is synchronous; cancelling removes the listener.
- Add `fromStream<T>(stream, {required T initial})` — creates an `Rx<T>` that syncs its value from a `Stream`.
- Add `ViewModel` base class with `onInit()` and `onDispose()` lifecycle hooks. `ViewModelScope` calls these automatically when the ViewModel enters and leaves the widget tree.

## 0.1.6

- Add `Rx.update(T Function(T previous) updater)` — updates the value by applying a function to the current value, without registering a tracking dependency on the read. Useful for counters, list mutations, and any transformation that depends on the previous state.

## 0.1.5

- Add `ObsBuilder` — like `Obs` but with a named `builder` parameter that receives `BuildContext`. Use when you need the context inside a reactive builder (theme, navigation, dialogs).

## 0.1.4

- Broaden `navhost` dependency constraint to `>=0.1.4` so navhost_state always resolves the latest compatible navhost version without requiring a manual bump.

## 0.1.3

- Update README install snippet to reference latest versions.

## 0.1.2

- Fix README example to use two-param route builder.

## 0.1.1

- ViewModels no longer need to extend `ChangeNotifier` — plain classes work with `.obs` + `Obs`.
- `ViewModelScope` stores any `Object`; only `ChangeNotifier` instances are auto-disposed.
- `rxRoutes()` updated for navhost 0.1.3 query parameter support.
- Added integration examples (get_it, injectable, dio, shared_preferences, freezed, hive, firebase, web_socket_channel, flutter_secure_storage).
- Added migration guides from Provider, Riverpod, GetX, and Bloc/Cubit.
- Added tests for `Rx<List>`, `Rx<Map>`, and plain class ViewModels.

## 0.1.0

- Initial release.
- `Rx<T>` reactive value wrapper with `.obs` extension.
- `Obs` auto-tracking widget — rebuilds only when read `Rx` values change.
- `ViewModelScope` for scoping `ChangeNotifier` ViewModels to the widget lifecycle.
- `rxRoutes()` helper to wrap navhost routes with `ViewModelScope` automatically.
- `context.viewModel()` extension for creating/retrieving scoped ViewModels.
- `ViewModelBuilder` convenience widget (create + subscribe in one step).
- `Listen` widget for subscribing to an existing scoped ViewModel.
