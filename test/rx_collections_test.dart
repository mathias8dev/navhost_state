import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navhost_state/navhost_state.dart';

void main() {
  group('RxList', () {
    testWidgets('add triggers rebuild', (tester) async {
      final items = RxList<String>();

      await tester.pumpWidget(MaterialApp(
        home: Obs(() => Text('${items.value.length}')),
      ));
      expect(find.text('0'), findsOneWidget);

      items.add('hello');
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('remove triggers rebuild', (tester) async {
      final items = RxList(['a', 'b', 'c']);

      await tester.pumpWidget(MaterialApp(
        home: Obs(() => Text('${items.value.length}')),
      ));
      expect(find.text('3'), findsOneWidget);

      items.remove('b');
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('clear triggers rebuild', (tester) async {
      final items = RxList([1, 2, 3]);

      await tester.pumpWidget(MaterialApp(
        home: Obs(() => Text(items.isEmpty ? 'empty' : 'filled')),
      ));
      expect(find.text('filled'), findsOneWidget);

      items.clear();
      await tester.pump();
      expect(find.text('empty'), findsOneWidget);
    });

    test('value returns unmodifiable list', () {
      final items = RxList([1, 2, 3]);
      expect(() => (items.value as dynamic).add(4), throwsUnsupportedError);
    });
  });

  group('RxMap', () {
    testWidgets('[]= triggers rebuild', (tester) async {
      final scores = RxMap<String, int>();

      await tester.pumpWidget(MaterialApp(
        home: Obs(() => Text('${scores.value.length}')),
      ));
      expect(find.text('0'), findsOneWidget);

      scores['Alice'] = 10;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('remove triggers rebuild', (tester) async {
      final scores = RxMap({'Alice': 10, 'Bob': 20});

      await tester.pumpWidget(MaterialApp(
        home: Obs(() => Text('${scores.value.length}')),
      ));
      expect(find.text('2'), findsOneWidget);

      scores.remove('Alice');
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('RxSet', () {
    testWidgets('add triggers rebuild', (tester) async {
      final selected = RxSet<int>();

      await tester.pumpWidget(MaterialApp(
        home: Obs(() => Text('${selected.value.length}')),
      ));
      expect(find.text('0'), findsOneWidget);

      selected.add(1);
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    test('add duplicate does not notify', () {
      final selected = RxSet({1, 2});
      var notified = false;
      selected.toStream().skip(1).listen((_) => notified = true);
      selected.add(1);
      expect(notified, false);
    });
  });
}
