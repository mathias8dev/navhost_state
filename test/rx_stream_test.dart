import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navhost_state/navhost_state.dart';

void main() {
  group('toStream / fromStream', () {
    test('toStream emits future changes synchronously', () async {
      final count = 0.obs;
      final values = <int>[];
      final sub = count.toStream().listen(values.add);
      count.value = 1;
      count.value = 2;
      expect(values, [1, 2]);
      await sub.cancel();
    });

    test('toStream does not emit current value on listen', () async {
      final count = 5.obs;
      final values = <int>[];
      final sub = count.toStream().listen(values.add);
      expect(values, isEmpty);
      count.value = 6;
      expect(values, [6]);
      await sub.cancel();
    });

    test('toStream stops emitting after cancel', () async {
      final count = 0.obs;
      final values = <int>[];
      final sub = count.toStream().listen(values.add);
      count.value = 1;
      await sub.cancel();
      count.value = 99;
      expect(values, [1]);
    });

    testWidgets('fromStream updates Rx when stream emits', (tester) async {
      final controller = StreamController<int>();
      final rx = fromStream(controller.stream, initial: 0);

      await tester.pumpWidget(MaterialApp(
        home: Obs(() => Text('${rx.value}')),
      ));
      expect(find.text('0'), findsOneWidget);

      controller.add(42);
      await tester.pump();
      expect(find.text('42'), findsOneWidget);

      await controller.close();
    });
  });
}
