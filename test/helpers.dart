import 'package:flutter/widgets.dart';
import 'package:navhost_state/navhost_state.dart';

class TestViewModel extends ChangeNotifier {
  static int instanceCount = 0;
  static int disposeCount = 0;

  static void reset() {
    instanceCount = 0;
    disposeCount = 0;
  }

  int count = 0;

  TestViewModel() {
    instanceCount++;
  }

  void increment() {
    count++;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeCount++;
    super.dispose();
  }
}

class PlainViewModel {
  static PlainViewModel? lastInstance;
  static int instanceCount = 0;

  final count = 0.obs;

  PlainViewModel() {
    lastInstance = this;
    instanceCount++;
  }

  void increment() => count.value++;
}

class LifecycleViewModel extends ViewModel {
  static int initCount = 0;
  static int disposeCount = 0;

  static void reset() {
    initCount = 0;
    disposeCount = 0;
  }

  @override
  void onInit() => initCount++;

  @override
  void onDispose() => disposeCount++;
}

class CounterViewModel extends ChangeNotifier {
  static CounterViewModel? lastInstance;

  final count = 0.obs;

  CounterViewModel() {
    lastInstance = this;
  }

  void increment() => count.value++;
}
