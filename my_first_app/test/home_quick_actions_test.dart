import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/screens/main_app.dart';

Future<void> _loadDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: MainApp()));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> _tapQuickAction(WidgetTester tester, String label) async {
  final Finder actionFinder = find.text(label);
  await tester.scrollUntilVisible(
    actionFinder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(actionFinder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Add Client quick action opens Clients tab', (
    WidgetTester tester,
  ) async {
    await _loadDashboard(tester);

    await _tapQuickAction(tester, 'Add Client');

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Create Invoice quick action opens Invoices tab', (
    WidgetTester tester,
  ) async {
    await _loadDashboard(tester);

    await _tapQuickAction(tester, 'Create Invoice');

    expect(find.text('Newest'), findsOneWidget);
  });

  testWidgets('GST Due Dates quick action opens calendar screen', (
    WidgetTester tester,
  ) async {
    await _loadDashboard(tester);

    await _tapQuickAction(tester, 'GST Due Dates');

    expect(find.text('Calendar & Due Management'), findsOneWidget);
  });

  testWidgets('Send Reminder quick action opens Reminders tab', (
    WidgetTester tester,
  ) async {
    await _loadDashboard(tester);

    await _tapQuickAction(tester, 'Send Reminder');

    expect(
      find.text('Smart reminder timeline with due status'),
      findsOneWidget,
    );
  });
}
