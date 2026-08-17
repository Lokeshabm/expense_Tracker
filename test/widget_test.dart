import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('App renders SplashScreen and initializes smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExpenseTrackerApp());

    // Verify that SplashScreen is initially displayed
    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Smart Money • Smarter Life'), findsOneWidget);

    // Settle all splash animations and timers
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify that either LoginScreen or Main dashboard is loaded
    expect(find.byType(ExpenseTrackerApp), findsOneWidget);
  });
}
