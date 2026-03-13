import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Onboarding flow renders', (WidgetTester tester) async {
    await tester.pumpWidget(const JIHCFitTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('Select Units'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
