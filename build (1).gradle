import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/theme.dart';

void main() {
  testWidgets('App theme builds without throwing', (WidgetTester tester) async {
    // A lightweight smoke test — full app testing would require mocking
    // Supabase and the notification plugin's platform channels, which is
    // out of scope for this starter project.
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: Text('Physio & Mobility')),
      ),
    );

    expect(find.text('Physio & Mobility'), findsOneWidget);
  });
}
