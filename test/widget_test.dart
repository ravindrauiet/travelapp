import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:metromate/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App launches through the splash to the home screen', (tester) async {
    await tester.pumpWidget(const MetromateApp());

    // Splash
    expect(find.text('Metromate'), findsOneWidget);

    // Splash animation (1.6 s) + hold (0.4 s), then home
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1)); // page transition

    expect(find.text('Where are you\nheading today?'), findsOneWidget);
    expect(find.text('Travel your way'), findsOneWidget);
  });
}
