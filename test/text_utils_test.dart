import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_flutter/core/utils/text_utils.dart';

void main() {
  group('initialOf', () {
    test('upper-cases the first letter', () {
      expect(initialOf('anna'), 'A');
      expect(initialOf('  ben '), 'B');
    });

    test('falls back for empty input', () {
      expect(initialOf(null), '?');
      expect(initialOf(''), '?');
      expect(initialOf('   '), '?');
      expect(initialOf(null, fallback: '-'), '-');
    });

    test('does not split emoji', () {
      expect(initialOf('😀 Max'), '😀');
    });
  });

  group('escapeLike', () {
    test('escapes wildcards and backslashes', () {
      expect(escapeLike('100%'), r'100\%');
      expect(escapeLike('a_b'), r'a\_b');
      expect(escapeLike(r'a\b'), r'a\\b');
    });

    test('leaves normal text alone', () {
      expect(escapeLike('Max Müller'), 'Max Müller');
    });
  });

  test('nullIfBlank', () {
    expect(nullIfBlank(null), isNull);
    expect(nullIfBlank('   '), isNull);
    expect(nullIfBlank('  hi '), 'hi');
  });

  group('parseTags', () {
    test('splits, trims and removes duplicates', () {
      expect(parseTags(' Musik, Gitarre ,Musik,, '), ['Musik', 'Gitarre']);
    });

    test('drops tags that are too long and caps the count', () {
      final raw = List.generate(15, (i) => 'tag$i').join(',');
      expect(parseTags(raw), hasLength(10));
      expect(parseTags('ok,${'x' * 31}'), ['ok']);
    });
  });
}
