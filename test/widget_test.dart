import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocolschlaff/app.dart';
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
    expect(find.text('Registro del día · toca una categoría para registrar tiempo'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Perfiles infantiles'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
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
}
