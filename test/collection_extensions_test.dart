import 'package:flutter_test/flutter_test.dart';
import 'package:navhost_state/navhost_state.dart';

void main() {
  // ─── IterableExtensions ────────────────────────────────────────────────────

  group('singleOrNull', () {
    test('returns the element when exactly one matches', () {
      expect([1, 2, 3].singleOrNull((e) => e == 2), 2);
    });

    test('returns null when no element matches', () {
      expect([1, 2, 3].singleOrNull((e) => e > 10), isNull);
    });

    test('returns null when more than one matches', () {
      expect([1, 2, 3].singleOrNull((e) => e > 1), isNull);
    });

    test('returns null on empty iterable', () {
      expect(<int>[].singleOrNull((e) => e == 1), isNull);
    });
  });

  group('filterNot', () {
    test('returns elements that do not match', () {
      expect([1, 2, 3, 4].filterNot((e) => e.isEven).toList(), [1, 3]);
    });

    test('returns all elements when predicate matches none', () {
      expect([1, 3, 5].filterNot((e) => e.isEven).toList(), [1, 3, 5]);
    });

    test('returns empty when predicate matches all', () {
      expect([2, 4, 6].filterNot((e) => e.isEven).toList(), isEmpty);
    });
  });

  group('groupBy', () {
    test('groups elements by key', () {
      final result = [1, 2, 3, 4].groupBy((e) => e.isEven ? 'even' : 'odd');
      expect(result['even'], [2, 4]);
      expect(result['odd'], [1, 3]);
    });

    test('returns empty map for empty iterable', () {
      expect(<int>[].groupBy((e) => e), isEmpty);
    });

    test('single group when all share the same key', () {
      expect(['a', 'b', 'c'].groupBy((_) => 'all'), {'all': ['a', 'b', 'c']});
    });
  });

  group('chunked', () {
    test('splits into chunks of given size', () {
      expect([1, 2, 3, 4, 5].chunked(2), [[1, 2], [3, 4], [5]]);
    });

    test('returns one chunk when size >= length', () {
      expect([1, 2, 3].chunked(5), [[1, 2, 3]]);
    });

    test('returns empty list for empty iterable', () {
      expect(<int>[].chunked(3), isEmpty);
    });

    test('exact fit produces equal-sized chunks', () {
      expect([1, 2, 3, 4].chunked(2), [[1, 2], [3, 4]]);
    });
  });

  group('count', () {
    test('returns total length when no predicate given', () {
      expect([1, 2, 3].count(), 3);
    });

    test('counts elements matching predicate', () {
      expect([1, 2, 3, 4].count((e) => e.isEven), 2);
    });

    test('returns 0 when nothing matches', () {
      expect([1, 3, 5].count((e) => e.isEven), 0);
    });

    test('returns 0 for empty iterable', () {
      expect(<int>[].count(), 0);
    });
  });

  group('sumOf', () {
    test('sums transformed values', () {
      expect([1, 2, 3].sumOf((e) => e * 2), 12);
    });

    test('returns 0 for empty iterable', () {
      expect(<int>[].sumOf((e) => e), 0);
    });

    test('works with doubles', () {
      expect([1.5, 2.5].sumOf((e) => e), 4.0);
    });
  });

  group('minByOrNull', () {
    test('returns element with smallest selector value', () {
      expect(['banana', 'apple', 'fig'].minByOrNull((s) => s.length), 'fig');
    });

    test('returns null for empty iterable', () {
      expect(<String>[].minByOrNull((s) => s.length), isNull);
    });

    test('returns first minimum when tied', () {
      final result = ['cat', 'dog', 'ant'].minByOrNull((s) => s.length);
      expect(result, 'cat'); // first with length 3
    });
  });

  group('maxByOrNull', () {
    test('returns element with largest selector value', () {
      expect(['fig', 'banana', 'apple'].maxByOrNull((s) => s.length), 'banana');
    });

    test('returns null for empty iterable', () {
      expect(<String>[].maxByOrNull((s) => s.length), isNull);
    });
  });

  group('associateBy', () {
    test('creates a map keyed by selector', () {
      final result = ['apple', 'banana'].associateBy((s) => s[0]);
      expect(result, {'a': 'apple', 'b': 'banana'});
    });

    test('later element wins on duplicate keys', () {
      final result = ['ant', 'ape'].associateBy((s) => s[0]);
      expect(result['a'], 'ape');
    });

    test('returns empty map for empty iterable', () {
      expect(<String>[].associateBy((s) => s), isEmpty);
    });
  });

  group('associate', () {
    test('creates a map from transform producing MapEntry', () {
      final result = [1, 2, 3].associate((e) => MapEntry('key$e', e * 10));
      expect(result, {'key1': 10, 'key2': 20, 'key3': 30});
    });

    test('returns empty map for empty iterable', () {
      expect(<int>[].associate((e) => MapEntry(e, e)), isEmpty);
    });
  });

  group('partition', () {
    test('splits into matching and non-matching lists', () {
      final (evens, odds) = [1, 2, 3, 4, 5].partition((e) => e.isEven);
      expect(evens, [2, 4]);
      expect(odds, [1, 3, 5]);
    });

    test('first list is empty when nothing matches', () {
      final (yes, no) = [1, 3, 5].partition((e) => e.isEven);
      expect(yes, isEmpty);
      expect(no, [1, 3, 5]);
    });

    test('second list is empty when everything matches', () {
      final (yes, no) = [2, 4, 6].partition((e) => e.isEven);
      expect(yes, [2, 4, 6]);
      expect(no, isEmpty);
    });

    test('both empty for empty iterable', () {
      final (yes, no) = <int>[].partition((e) => e.isEven);
      expect(yes, isEmpty);
      expect(no, isEmpty);
    });
  });

  group('distinctBy', () {
    test('removes duplicates by key, preserving first occurrence', () {
      final result = ['apple', 'ant', 'banana', 'bear'].distinctBy((s) => s[0]);
      expect(result, ['apple', 'banana']);
    });

    test('preserves all elements when all keys are unique', () {
      expect([1, 2, 3].distinctBy((e) => e), [1, 2, 3]);
    });

    test('returns empty list for empty iterable', () {
      expect(<int>[].distinctBy((e) => e), isEmpty);
    });
  });

  group('flatMap', () {
    test('maps each element and flattens', () {
      expect([1, 2, 3].flatMap((e) => [e, e * 10]), [1, 10, 2, 20, 3, 30]);
    });

    test('returns empty list for empty iterable', () {
      expect(<int>[].flatMap((e) => [e]), isEmpty);
    });

    test('handles empty inner iterables', () {
      expect([1, 2].flatMap((_) => <int>[]), isEmpty);
    });
  });

  group('zip', () {
    test('pairs elements with transform', () {
      expect([1, 2, 3].zip([4, 5, 6], (a, b) => a + b), [5, 7, 9]);
    });

    test('stops at the shorter iterable', () {
      expect([1, 2, 3].zip([4, 5], (a, b) => a + b), [5, 7]);
      expect([1, 2].zip([4, 5, 6], (a, b) => a + b), [5, 7]);
    });

    test('returns empty list when either is empty', () {
      expect([1, 2].zip(<int>[], (a, b) => a + b), isEmpty);
    });
  });

  group('joinToString', () {
    test('joins with default separator', () {
      expect([1, 2, 3].joinToString(), '1, 2, 3');
    });

    test('joins with custom separator', () {
      expect([1, 2, 3].joinToString(separator: ' | '), '1 | 2 | 3');
    });

    test('applies transform before joining', () {
      expect([1, 2, 3].joinToString(transform: (e) => '#$e'), '#1, #2, #3');
    });

    test('returns empty string for empty iterable', () {
      expect(<int>[].joinToString(), '');
    });
  });

  group('onEach', () {
    test('executes action on each element and returns same iterable', () {
      final log = <int>[];
      final result = [1, 2, 3].onEach(log.add);
      expect(log, [1, 2, 3]);
      expect(result, [1, 2, 3]);
    });

    test('returns empty iterable unchanged', () {
      final log = <int>[];
      <int>[].onEach(log.add);
      expect(log, isEmpty);
    });
  });

  group('drop', () {
    test('drops first n elements', () {
      expect([1, 2, 3, 4, 5].drop(2).toList(), [3, 4, 5]);
    });

    test('drop(0) returns all elements', () {
      expect([1, 2, 3].drop(0).toList(), [1, 2, 3]);
    });

    test('drop(n >= length) returns empty', () {
      expect([1, 2].drop(5).toList(), isEmpty);
    });
  });

  group('dropWhile', () {
    test('drops elements while predicate holds', () {
      expect([1, 2, 3, 4].dropWhile((e) => e < 3).toList(), [3, 4]);
    });

    test('returns all when predicate is immediately false', () {
      expect([3, 4, 5].dropWhile((e) => e < 3).toList(), [3, 4, 5]);
    });

    test('returns empty when predicate always holds', () {
      expect([1, 2, 3].dropWhile((e) => e < 10).toList(), isEmpty);
    });
  });

  // ─── ListExtensions ────────────────────────────────────────────────────────

  group('sortedByDescending', () {
    test('sorts by selector descending', () {
      expect(['fig', 'banana', 'apple'].sortedByDescending((s) => s.length),
          ['banana', 'apple', 'fig']);
    });

    test('does not mutate the original list', () {
      final original = ['c', 'a', 'b'];
      original.sortedByDescending((s) => s);
      expect(original, ['c', 'a', 'b']);
    });

    test('returns empty list for empty input', () {
      expect(<String>[].sortedByDescending((s) => s.length), isEmpty);
    });
  });

  group('indices', () {
    test('returns 0..length-1', () {
      expect([10, 20, 30].indices.toList(), [0, 1, 2]);
    });

    test('returns empty for empty list', () {
      expect(<int>[].indices.toList(), isEmpty);
    });

    test('single element list has index 0', () {
      expect(['x'].indices.toList(), [0]);
    });
  });

  // ─── MapExtensions ─────────────────────────────────────────────────────────

  group('mapValues', () {
    test('transforms values, preserving keys', () {
      expect({'a': 1, 'b': 2}.mapValues((k, v) => v * 10),
          {'a': 10, 'b': 20});
    });

    test('returns empty map for empty input', () {
      expect(<String, int>{}.mapValues((k, v) => v), isEmpty);
    });
  });

  group('mapKeys', () {
    test('transforms keys, preserving values', () {
      expect({'a': 1, 'b': 2}.mapKeys((k, v) => k.toUpperCase()),
          {'A': 1, 'B': 2});
    });

    test('returns empty map for empty input', () {
      expect(<String, int>{}.mapKeys((k, v) => k), isEmpty);
    });
  });

  group('filterKeys', () {
    test('keeps entries whose key matches', () {
      expect({'a': 1, 'b': 2, 'c': 3}.filterKeys((k) => k != 'b'),
          {'a': 1, 'c': 3});
    });

    test('returns empty when no key matches', () {
      expect({'a': 1}.filterKeys((k) => k == 'z'), isEmpty);
    });
  });

  group('filterValues', () {
    test('keeps entries whose value matches', () {
      expect({'a': 1, 'b': 2, 'c': 3}.filterValues((v) => v > 1),
          {'b': 2, 'c': 3});
    });

    test('returns empty when no value matches', () {
      expect({'a': 1}.filterValues((v) => v > 10), isEmpty);
    });
  });

  group('filter (Map)', () {
    test('keeps entries where key and value match', () {
      expect(
        {'a': 1, 'b': 2, 'c': 3}.filter((k, v) => k != 'b' && v > 1),
        {'c': 3},
      );
    });

    test('returns all when all match', () {
      final m = {'x': 1, 'y': 2};
      expect(m.filter((k, v) => true), {'x': 1, 'y': 2});
    });
  });

  group('getOrDefault', () {
    test('returns value when key exists', () {
      expect({'a': 1}.getOrDefault('a', 99), 1);
    });

    test('returns default when key is absent', () {
      expect({'a': 1}.getOrDefault('z', 99), 99);
    });
  });

  group('getOrElse', () {
    test('returns value when key exists', () {
      expect({'a': 42}.getOrElse('a', () => 0), 42);
    });

    test('calls orElse when key is absent', () {
      var called = false;
      final result = <String, int>{}.getOrElse('x', () {
        called = true;
        return -1;
      });
      expect(result, -1);
      expect(called, isTrue);
    });
  });

  group('none (Map)', () {
    test('returns true when no entry matches', () {
      expect({'a': 1, 'b': 2}.none((k, v) => v > 10), isTrue);
    });

    test('returns false when at least one entry matches', () {
      expect({'a': 1, 'b': 20}.none((k, v) => v > 10), isFalse);
    });

    test('returns true for empty map', () {
      expect(<String, int>{}.none((k, v) => true), isTrue);
    });
  });

  group('all (Map)', () {
    test('returns true when all entries match', () {
      expect({'a': 2, 'b': 4}.all((k, v) => v.isEven), isTrue);
    });

    test('returns false when any entry does not match', () {
      expect({'a': 2, 'b': 3}.all((k, v) => v.isEven), isFalse);
    });

    test('returns true for empty map', () {
      expect(<String, int>{}.all((k, v) => false), isTrue);
    });
  });

  group('count (Map)', () {
    test('returns total size when no predicate given', () {
      expect({'a': 1, 'b': 2}.count(), 2);
    });

    test('counts entries matching predicate', () {
      expect({'a': 1, 'b': 2, 'c': 3}.count((k, v) => v > 1), 2);
    });

    test('returns 0 for empty map', () {
      expect(<String, int>{}.count(), 0);
    });
  });

  group('minByOrNull (Map)', () {
    test('returns entry with smallest selector value', () {
      final result = {'b': 2, 'a': 1, 'c': 3}.minByOrNull((k, v) => v);
      expect(result?.key, 'a');
      expect(result?.value, 1);
    });

    test('returns null for empty map', () {
      expect(<String, int>{}.minByOrNull((k, v) => v), isNull);
    });
  });

  group('maxByOrNull (Map)', () {
    test('returns entry with largest selector value', () {
      final result = {'a': 1, 'b': 3, 'c': 2}.maxByOrNull((k, v) => v);
      expect(result?.key, 'b');
      expect(result?.value, 3);
    });

    test('returns null for empty map', () {
      expect(<String, int>{}.maxByOrNull((k, v) => v), isNull);
    });
  });

  group('toList (Map)', () {
    test('converts entries to list using transform', () {
      final result = {'a': 1, 'b': 2}.toList((k, v) => '$k=$v');
      expect(result, containsAll(['a=1', 'b=2']));
      expect(result.length, 2);
    });

    test('returns empty list for empty map', () {
      expect(<String, int>{}.toList((k, v) => v), isEmpty);
    });
  });
}
