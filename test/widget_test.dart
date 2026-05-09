import 'package:flutter_test/flutter_test.dart';

import 'package:wearth/main.dart';

void main() {
  testWidgets('WearthApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WearthApp());

    // Verify that the home screen loads with the title
    expect(find.text('WEARTH'), findsOneWidget);
    expect(find.text('OYNA'), findsOneWidget);
  });
}
