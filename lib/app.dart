import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization.dart';
import 'screens/child_profiles_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _languageController = AppLanguageController();

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _languageController,
      builder: (context, _) => AppLanguageScope(
        controller: _languageController,
        child: MaterialApp(
          title: 'Schlaffapp',
          locale: Locale(_languageController.language.localeCode),
          supportedLocales: const [
            Locale('es'),
            Locale('pt'),
            Locale('de'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const ChildProfilesPage(),
        ),
      ),
    );
  }
}
