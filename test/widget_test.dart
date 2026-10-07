import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocolschlaff/app.dart';
import 'package:protocolschlaff/data/sleep_data.dart';
import 'package:protocolschlaff/screens/sleep_timer_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Muestra la pantalla inicial de perfiles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Perfiles infantiles'), findsOneWidget);
    expect(find.text('Crear perfil'), findsOneWidget);
  });

  testWidgets('Permite crear perfiles y volver para elegir otro', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Crear perfil').last);
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsOneWidget);
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Registro del día · toca una categoría para registrar tiempo'),
        findsOneWidget);
    expect(find.byTooltip('Atrás'), findsOneWidget);

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.text('Perfiles infantiles'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
  });

  testWidgets('Permite cambiar el idioma desde la pantalla inicial', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.text('Kinderprofile'), findsOneWidget);
    expect(find.text('🇩🇪'), findsOneWidget);
  });

  testWidgets('Permite crear un segundo perfil desde la pantalla inicial', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Crear perfil').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear otro perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.tap(find.text('Crear perfil').last);
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El temporizador ofrece captura cronometrada y manual', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SleepTimerPage(question: 'Dormir en su propia cama'),
      ),
    );

    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Terminar'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
  });

  testWidgets('El selector de hora manual muestra AM y PM', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SleepTimerPage(question: 'Dormir en su propia cama'),
      ),
    );

    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Inicio:'));
    await tester.pumpAndSettle();

    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'AM|PM')), findsNWidgets(2));
  });

  testWidgets('Muestra todas las mediciones repetidas en el historial', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const profile = ChildProfile(id: 'history-child', name: 'Alex');
    final today = DateTime.now();
    final day = SleepDay(
      dateKey: dateKeyFor(today),
      entries: const [
        SleepEntry(
          question: 'Dormir en su propia cama',
          minutes: 120,
          startTime: '02:00',
          endTime: '04:00',
        ),
        SleepEntry(
          question: 'Dormir en su propia cama',
          minutes: 180,
          startTime: '09:00',
          endTime: '12:00',
        ),
      ],
    );
    await SleepDataStore.save([
      profile
    ], {
      profile.id: [day],
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    expect(find.text('Historial del día (2)'), findsNothing);
    await tester.tap(find.text('Dormir en su propia cama').first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Historial del día (2)'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Historial del día (2)'), findsOneWidget);
    expect(find.text('02:00 a. m. – 04:00 a. m.'), findsOneWidget);
    expect(find.text('09:00 a. m. – 12:00 p. m.'), findsOneWidget);
    expect(find.text('Dormir en su propia cama').evaluate().length,
        greaterThanOrEqualTo(2));
  });
}
