## 0.1.0

- Initial release.
- `Rx<T>` reactive value wrapper with `.obs` extension.
- `Obs` auto-tracking widget — rebuilds only when read `Rx` values change.
- `ViewModelScope` for scoping `ChangeNotifier` ViewModels to the widget lifecycle.
- `rxRoutes()` helper to wrap navhost routes with `ViewModelScope` automatically.
- `context.viewModel()` extension for creating/retrieving scoped ViewModels.
- `ViewModelBuilder` convenience widget (create + subscribe in one step).
- `Listen` widget for subscribing to an existing scoped ViewModel.
