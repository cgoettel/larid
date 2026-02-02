import 'package:flutter_test/flutter_test.dart';

import 'package:larid/main.dart';

void main() {
  testWidgets('LarID app builds without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LarIDApp());

    // Wait for initial frame
    await tester.pump();

    // App should build without throwing
    // (detailed UI tests can be added later)
  });
}
