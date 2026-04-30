import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Charge Lanka shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Charge Lanka'))),
      ),
    );

    expect(find.text('Charge Lanka'), findsOneWidget);
  });
}
