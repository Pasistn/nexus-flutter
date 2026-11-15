import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_flutter/core/utils/date_format.dart';
import 'package:nexus_flutter/core/utils/geo_utils.dart';

void main() {
  group('distanceKm', () {
    test('is zero for the same point', () {
      expect(distanceKm(48.13, 11.58, 48.13, 11.58), 0);
    });

    test('Munich → Berlin is roughly 500 km', () {
      final d = distanceKm(48.1351, 11.5820, 52.5200, 13.4050);
      expect(d, closeTo(504, 5));
    });

    test('is symmetric', () {
      final a = distanceKm(50.11, 8.68, 53.55, 9.99);
      final b = distanceKm(53.55, 9.99, 50.11, 8.68);
      expect(a, closeTo(b, 1e-9));
    });
  });

  group('chat list time', () {
    final now = DateTime(2026, 5, 20, 15, 30);

    test('recent messages', () {
      expect(formatChatListTime(now.subtract(const Duration(seconds: 20)), now: now), 'Jetzt');
      expect(formatChatListTime(now.subtract(const Duration(minutes: 12)), now: now), '12 min');
    });

    test('same day shows clock time', () {
      expect(formatChatListTime(DateTime(2026, 5, 20, 8, 5), now: now), '08:05');
    });

    test('yesterday and older', () {
      expect(formatChatListTime(DateTime(2026, 5, 19, 23, 0), now: now), 'Gestern');
      expect(formatChatListTime(DateTime(2026, 5, 2, 10, 0), now: now), '2.5.');
    });
  });

  test('message time includes the date for older messages', () {
    final now = DateTime(2026, 5, 20, 15, 30);
    expect(formatMessageTime(DateTime(2026, 5, 20, 9, 1), now: now), '09:01');
    expect(formatMessageTime(DateTime(2026, 5, 19, 9, 1), now: now), 'Gestern, 09:01');
    expect(formatMessageTime(DateTime(2026, 4, 1, 9, 1), now: now), '1.4.2026, 09:01');
  });
}
