import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/main.dart';

void main() {
  testWidgets('Login screen renders expected controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create New Account'), findsOneWidget);
  });

  testWidgets('Login validation appears on empty submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Enter email'), findsOneWidget);
    expect(find.text('Enter password'), findsOneWidget);
  });
}
