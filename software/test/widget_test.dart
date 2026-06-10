import 'package:flutter_test/flutter_test.dart';
import 'package:neurovision_ai/main.dart';

void main() {
  testWidgets('NeuroVision AI app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeuroVisionApp());
    // Verify the app renders without crashing
    expect(find.byType(NeuroVisionApp), findsOneWidget);
  });
}
