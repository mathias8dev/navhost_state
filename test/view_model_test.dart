import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navhost/navhost.dart';
import 'package:navhost_state/navhost_state.dart';

import 'helpers.dart';

void main() {
  group('ViewModel lifecycle', () {
    testWidgets('onInit called when ViewModel enters ViewModelScope',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => Builder(builder: (context) {
                context.viewModel(() => LifecycleViewModel());
                return const Text('Home');
              })),
        ]),
      );
      LifecycleViewModel.reset();

      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      expect(LifecycleViewModel.initCount, 1);
    });

    testWidgets('onDispose called when route is popped', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/detail', (p, q) => Builder(builder: (context) {
                context.viewModel(() => LifecycleViewModel());
                return const Text('Detail');
              })),
        ]),
      );
      LifecycleViewModel.reset();

      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      nav.navigate('/detail');
      await tester.pumpAndSettle();
      expect(LifecycleViewModel.initCount, 1);
      expect(LifecycleViewModel.disposeCount, 0);

      nav.pop();
      await tester.pumpAndSettle();
      expect(LifecycleViewModel.disposeCount, 1);
    });
  });

  group('Scoped ViewModel', () {
    testWidgets('viewModel returns same instance across rebuilds',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => Builder(builder: (context) {
                final vm = context.viewModel(() => TestViewModel());
                return Text('count:${vm.count}');
              })),
          NavRoute('/b', (p, q) => const Text('B')),
        ]),
      );
      TestViewModel.reset();
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);
      expect(TestViewModel.instanceCount, 1);

      nav.notifyListeners();
      await tester.pumpAndSettle();
      expect(TestViewModel.instanceCount, 1);
    });

    testWidgets('pop disposes the viewModel', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/detail', (p, q) => Builder(builder: (context) {
                final vm = context.viewModel(() => TestViewModel());
                return Text('count:${vm.count}');
              })),
        ]),
      );
      TestViewModel.reset();
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      nav.navigate('/detail');
      await tester.pumpAndSettle();
      expect(TestViewModel.instanceCount, 1);
      expect(TestViewModel.disposeCount, 0);

      nav.pop();
      await tester.pumpAndSettle();
      expect(TestViewModel.disposeCount, 1);
    });

    testWidgets('navigate with replace disposes all viewModels',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => Builder(builder: (context) {
                context.viewModel(() => TestViewModel());
                return const Text('Home');
              })),
          NavRoute('/a', (p, q) => Builder(builder: (context) {
                context.viewModel(() => TestViewModel());
                return const Text('A');
              })),
          NavRoute('/b', (p, q) => const Text('B')),
        ]),
      );
      TestViewModel.reset();
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();
      nav.navigate('/a');
      await tester.pumpAndSettle();
      expect(TestViewModel.instanceCount, 2);

      nav.navigate('/b', replace: true);
      await tester.pumpAndSettle();
      expect(TestViewModel.disposeCount, 2);
    });

    testWidgets('same type on different routes yields separate instances',
        (tester) async {
      late TestViewModel homeVm;
      late TestViewModel detailVm;
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => Builder(builder: (context) {
                homeVm = context.viewModel(() => TestViewModel());
                return const Text('Home');
              })),
          NavRoute('/detail', (p, q) => Builder(builder: (context) {
                detailVm = context.viewModel(() => TestViewModel());
                return const Text('Detail');
              })),
        ]),
      );
      TestViewModel.reset();
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      nav.navigate('/detail');
      await tester.pumpAndSettle();

      expect(TestViewModel.instanceCount, 2);
      expect(identical(homeVm, detailVm), false);
    });

    testWidgets('popUntil disposes intermediate viewModels', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/a', (p, q) => Builder(builder: (context) {
                context.viewModel(() => TestViewModel());
                return const Text('A');
              })),
          NavRoute('/b', (p, q) => Builder(builder: (context) {
                context.viewModel(() => TestViewModel());
                return const Text('B');
              })),
          NavRoute('/c', (p, q) => Builder(builder: (context) {
                context.viewModel(() => TestViewModel());
                return const Text('C');
              })),
        ]),
      );
      TestViewModel.reset();
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      await tester.pumpAndSettle();
      expect(TestViewModel.instanceCount, 3);

      nav.popUntil('/');
      await tester.pumpAndSettle();
      expect(TestViewModel.disposeCount, 3);
    });

    testWidgets('ViewModelBuilder creates and listens to viewModel',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => ViewModelBuilder<TestViewModel>(
                factory: () => TestViewModel(),
                builder: (context, vm, child) => Column(children: [
                  Text('count:${vm.count}'),
                  ElevatedButton(onPressed: vm.increment, child: const Text('inc')),
                ]),
              )),
        ]),
      );
      TestViewModel.reset();
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);

      await tester.tap(find.text('inc'));
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('manual ViewModelScope works without rxRoutes', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute('/', (p, q) => ViewModelScope(
                child: Builder(builder: (context) {
                  final vm = context.viewModel(() => TestViewModel());
                  return Text('count:${vm.count}');
                }),
              )),
        ],
      );
      TestViewModel.reset();
      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);
      expect(TestViewModel.instanceCount, 1);
    });
  });

  group('Plain class ViewModel (no ChangeNotifier)', () {
    testWidgets('works with context.viewModel and Obs', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => Builder(builder: (context) {
                final vm = context.viewModel(() => PlainViewModel());
                return Obs(() => Text('count:${vm.count.value}'));
              })),
        ]),
      );

      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);

      PlainViewModel.lastInstance!.increment();
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('same instance reused across rebuilds', (tester) async {
      PlainViewModel.instanceCount = 0;
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => Builder(builder: (context) {
                final vm = context.viewModel(() => PlainViewModel());
                return Obs(() => Text('count:${vm.count.value}'));
              })),
        ]),
      );

      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();
      expect(PlainViewModel.instanceCount, 1);

      nav.notifyListeners();
      await tester.pumpAndSettle();
      expect(PlainViewModel.instanceCount, 1);
    });

    testWidgets('does not crash on dispose (no dispose method)', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => const Text('Home')),
          NavRoute('/detail', (p, q) => Builder(builder: (context) {
                context.viewModel(() => PlainViewModel());
                return const Text('Detail');
              })),
        ]),
      );

      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();

      nav.navigate('/detail');
      await tester.pumpAndSettle();

      nav.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('Obs + viewModel integration', () {
    testWidgets('Obs rebuilds on Rx change inside scoped ViewModel',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (p, q) => Builder(builder: (context) {
                final vm = context.viewModel(() => CounterViewModel());
                return Obs(() => Text('count:${vm.count.value}'));
              })),
        ]),
      );

      await tester.pumpWidget(MaterialApp(home: NavHost(navController: nav)));
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);

      CounterViewModel.lastInstance!.increment();
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
    });
  });
}
