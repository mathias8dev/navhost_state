/// Base class for ViewModels that need lifecycle hooks.
///
/// Implement [onInit] for setup that should run when the ViewModel first
/// enters the widget tree, and [onDispose] for cleanup when it leaves.
///
/// Works with both state hoisting (called manually) and [ViewModelScope]
/// (called automatically).
///
/// ```dart
/// class PostListViewModel extends ViewModel {
///   final _posts = RxList<Post>();
///   List<Post> get posts => _posts.value;
///
///   @override
///   void onInit() => loadPosts();
///
///   @override
///   void onDispose() => _subscription?.cancel();
/// }
/// ```
abstract class ViewModel {
  /// Called once when this ViewModel is first stored in a [ViewModelScope],
  /// or manually after construction when using state hoisting.
  void onInit() {}

  /// Called when the enclosing [ViewModelScope] is disposed,
  /// or manually when the owning widget is torn down.
  void onDispose() {}
}
