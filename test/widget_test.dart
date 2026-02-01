// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:finance_tracker/main.dart';
import 'package:finance_tracker/state/app_state.dart';

void main() {
  testWidgets('Finance tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const FinanceTrackerApp(),
      ),
    );

    // Verify that the home screen is displayed.
    expect(find.text('Басты бет'), findsOneWidget);
    expect(find.text('Баланс'), findsOneWidget);
  });
}
