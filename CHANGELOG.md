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
