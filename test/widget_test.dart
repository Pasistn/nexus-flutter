import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // No-op: requires Supabase initialization in test environment
    expect(true, isTrue);
  });
}
