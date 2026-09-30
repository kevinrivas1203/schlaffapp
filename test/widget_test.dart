import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocolschlaff/app.dart';

import 'package:protocolschlaff/screens/sleep_timer_page.dart';

void main() {
  testWidgets('La lista muestra el texto en alemán', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Tippe hier, um die Zeit zu erfassen'), findsWidgets);
  });

  testWidgets('La página del temporizador muestra el reloj con hora inicial', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SleepTimerPage(question: 'Schlafen im eigenen Bett'),
      ),
    );

    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('Starten'), findsOneWidget);
    expect(find.text('Beenden'), findsOneWidget);
  });
}
