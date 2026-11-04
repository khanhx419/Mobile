import 'package:flutter_test/flutter_test.dart';
import 'package:english_discipline/learning.dart';

void main() {
  group('IPA alignment and scoring', () {
    test('all lessons have curated IPA', () {
      for (final lesson in lessons) {
        expect(lesson.ipa, isNotEmpty);
        expect(assess(lesson.text, lesson.text).score, 100);
      }
    });
    test('normalizes punctuation and case', () {
      expect(assess('thank you', 'Thank, YOU!').score, 100);
    });
    test('th/t substitution produces specific exercise', () {
      final r = assess('thank you', 'tank you');
      expect(r.score, lessThan(100));
      expect(r.pairs.any((p) => p.expected == 'θ' && p.heard == 't'), isTrue);
      expect(r.tips.join(), contains('đầu lưỡi'));
    });
    test('short/long vowel confusion is highlighted', () {
      final r = assess('the ship is big', 'the sheep is big');
      expect(r.pairs.any((p) => p.expected == 'ɪ' && p.heard == 'iː'), isTrue);
      expect(r.tips.join(), contains('ship–sheep'));
    });
    test('missing and extra sounds count against score', () {
      expect(
        assess('hello world', 'hello').pairs.any((p) => p.heard == null),
        isTrue,
      );
      expect(
        assess('hello', 'hello world').pairs.any((p) => p.expected == null),
        isTrue,
      );
      expect(assess('hello', 'hello world').score, lessThan(100));
    });
    test('unknown and empty transcripts are not given fake scores', () {
      expect(assess('hello world', 'unlistedword').score, isNull);
      expect(assess('hello world', '').score, isNull);
      expect(assess('', 'hello').score, isNull);
    });
    test(
      'alignment reconstructs both inputs including insertions/deletions',
      () {
        for (final a in <List<String>>[
          [],
          ['θ'],
          ['a', 'b', 'c'],
        ]) {
          for (final b in <List<String>>[
            [],
            ['t'],
            ['a', 'c', 'd', 'e'],
          ]) {
            final pairs = align(a, b);
            expect(
              pairs.map((p) => p.expected).whereType<String>().toList(),
              a,
            );
            expect(pairs.map((p) => p.heard).whereType<String>().toList(), b);
          }
        }
      },
    );
  });
  group('calendar streak', () {
    final today = DateTime(2026, 10, 31, 20);
    test('empty, today only and duplicate sessions', () {
      expect(streak([], today), 0);
      expect(streak(['2026-10-31', '2026-10-31'], today), 1);
    });
    test('retains yesterday streak until today is over', () {
      expect(streak(['2026-10-29', '2026-10-30'], today), 2);
    });
    test('breaks at missing calendar day', () {
      expect(streak(['2026-10-28', '2026-10-31'], today), 1);
      expect(streak(['2026-10-29'], today), 0);
    });
    test('crosses month/year boundaries, ignores future records', () {
      expect(
        streak([
          '2025-12-31',
          '2026-01-01',
          '2026-01-02',
        ], DateTime(2026, 1, 1)),
        2,
      );
    });
  });
}
