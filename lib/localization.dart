import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  spanish('es', '🇪🇸', 'Español'),
  portuguese('pt', '🇵🇹', 'Português'),
  german('de', '🇩🇪', 'Deutsch');

  const AppLanguage(this.localeCode, this.flag, this.name);

  final String localeCode;
  final String flag;
  final String name;

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
        (language) => language.localeCode == code,
        orElse: () => AppLanguage.spanish,
      );
}

class AppLanguageController extends ChangeNotifier {
  AppLanguageController() {
    _load();
  }

  static const _preferenceKey = 'schlaffapp_language';
  AppLanguage _language = AppLanguage.spanish;

  AppLanguage get language => _language;

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = AppLanguage.fromCode(
      preferences.getString(_preferenceKey),
    );
    if (savedLanguage == _language) return;
    _language = savedLanguage;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, language.localeCode);
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguage of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    return scope?.notifier?.language ?? AppLanguage.spanish;
  }

  static AppLanguageController controllerOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    return scope!.notifier!;
  }
}

const _translations = <String, Map<AppLanguage, String>>{
  'Perfiles infantiles': {
    AppLanguage.portuguese: 'Perfis infantis',
    AppLanguage.german: 'Kinderprofile',
  },
  'Crear perfil': {
    AppLanguage.portuguese: 'Criar perfil',
    AppLanguage.german: 'Profil erstellen',
  },
  'Nombre del niño o niña': {
    AppLanguage.portuguese: 'Nome da criança',
    AppLanguage.german: 'Name des Kindes',
  },
  'Cancelar': {
    AppLanguage.portuguese: 'Cancelar',
    AppLanguage.german: 'Abbrechen',
  },
  'Borrar perfil': {
    AppLanguage.portuguese: 'Excluir perfil',
    AppLanguage.german: 'Profil löschen',
  },
  'Confirmar borrado': {
    AppLanguage.portuguese: 'Confirmar exclusão',
    AppLanguage.german: 'Löschen bestätigen',
  },
  '¿Estás segura de que quieres borrar el perfil "{name}"?': {
    AppLanguage.portuguese:
        'Tem certeza de que deseja excluir o perfil "{name}"?',
    AppLanguage.german: 'Möchtest du das Profil „{name}“ wirklich löschen?',
  },
  'Crea un perfil para empezar el registro del sueño.': {
    AppLanguage.portuguese: 'Crie um perfil para começar a acompanhar o sono.',
    AppLanguage.german:
        'Erstelle ein Profil, um mit der Schlafaufzeichnung zu beginnen.',
  },
  '¿De quién quieres consultar el registro?': {
    AppLanguage.portuguese: 'De quem você quer consultar o registro?',
    AppLanguage.german: 'Wessen Aufzeichnungen möchtest du ansehen?',
  },
  'Abrir registro y cuestionario': {
    AppLanguage.portuguese: 'Abrir registro e questionário',
    AppLanguage.german: 'Aufzeichnungen und Fragebogen öffnen',
  },
  'Crear otro perfil': {
    AppLanguage.portuguese: 'Criar outro perfil',
    AppLanguage.german: 'Weiteres Profil erstellen',
  },
  'Idioma': {
    AppLanguage.portuguese: 'Idioma',
    AppLanguage.german: 'Sprache',
  },
  'Resultados e informes': {
    AppLanguage.portuguese: 'Resultados e relatórios',
    AppLanguage.german: 'Ergebnisse und Berichte',
  },
  'Cuestionario': {
    AppLanguage.portuguese: 'Questionário',
    AppLanguage.german: 'Fragebogen',
  },
  'Registro del día · toca una categoría para registrar tiempo': {
    AppLanguage.portuguese:
        'Registro do dia · toque numa categoria para registrar o tempo',
    AppLanguage.german:
        'Tagesprotokoll · Tippe auf eine Kategorie, um die Zeit zu erfassen',
  },
  'Sin tiempo registrado': {
    AppLanguage.portuguese: 'Nenhum tempo registrado',
    AppLanguage.german: 'Keine Zeit erfasst',
  },
  'Total: {time} · {count} registro(s)': {
    AppLanguage.portuguese: 'Total: {time} · {count} registro(s)',
    AppLanguage.german: 'Gesamt: {time} · {count} Eintrag/Einträge',
  },
  '{hours} h {minutes} min': {
    AppLanguage.portuguese: '{hours} h {minutes} min',
    AppLanguage.german: '{hours} Std. {minutes} Min.',
  },
  'Cuestionario diario': {
    AppLanguage.portuguese: 'Questionário diário',
    AppLanguage.german: 'Täglicher Fragebogen',
  },
  'Fecha del registro: {date}': {
    AppLanguage.portuguese: 'Data do registro: {date}',
    AppLanguage.german: 'Datum des Eintrags: {date}',
  },
  'Guardar cuestionario': {
    AppLanguage.portuguese: 'Salvar questionário',
    AppLanguage.german: 'Fragebogen speichern',
  },
  '¿A qué hora se despertó hoy?': {
    AppLanguage.portuguese: 'A que horas acordou hoje?',
    AppLanguage.german: 'Um wie viel Uhr ist das Kind heute aufgewacht?',
  },
  '¿A qué hora se acostó por la noche?': {
    AppLanguage.portuguese: 'A que horas foi dormir à noite?',
    AppLanguage.german:
        'Um wie viel Uhr ist das Kind abends schlafen gegangen?',
  },
  '¿Cómo fue su estado de ánimo por la noche?': {
    AppLanguage.portuguese: 'Como estava o humor à noite?',
    AppLanguage.german: 'Wie war die Stimmung am Abend?',
  },
  '¿Cómo estaba antes de acostarse?': {
    AppLanguage.portuguese: 'Como estava antes de dormir?',
    AppLanguage.german: 'Wie war die Stimmung vor dem Schlafengehen?',
  },
  'Tres momentos bonitos del día': {
    AppLanguage.portuguese: 'Três momentos bons do dia',
    AppLanguage.german: 'Drei schöne Momente des Tages',
  },
  '¿Qué le causó estrés hoy?': {
    AppLanguage.portuguese: 'O que causou estresse hoje?',
    AppLanguage.german: 'Was hat heute Stress verursacht?',
  },
  'Observaciones adicionales': {
    AppLanguage.portuguese: 'Observações adicionais',
    AppLanguage.german: 'Zusätzliche Beobachtungen',
  },
  'Registrar tiempo': {
    AppLanguage.portuguese: 'Registrar tempo',
    AppLanguage.german: 'Zeit erfassen',
  },
  'Hora de inicio': {
    AppLanguage.portuguese: 'Hora de início',
    AppLanguage.german: 'Startzeit',
  },
  'Hora de finalización': {
    AppLanguage.portuguese: 'Hora de término',
    AppLanguage.german: 'Endzeit',
  },
  'La hora de inicio y fin no pueden ser iguales.': {
    AppLanguage.portuguese:
        'O horário de início e de término não pode ser igual.',
    AppLanguage.german: 'Start- und Endzeit dürfen nicht identisch sein.',
  },
  'El período de despertar debe quedar dentro de un período de sueño registrado.':
      {
    AppLanguage.portuguese:
        'O período acordado deve ocorrer dentro de um período de sono registrado.',
    AppLanguage.german:
        'Der Wachzeitraum muss innerhalb eines erfassten Schlafzeitraums liegen.',
  },
  'Este horario se solapa con un período de sueño.': {
    AppLanguage.portuguese: 'Este horário coincide com um período de sono.',
    AppLanguage.german:
        'Dieser Zeitraum überschneidet sich mit einem Schlafzeitraum.',
  },
  'Este horario se solapa con otra actividad registrada.': {
    AppLanguage.portuguese:
        'Este horário coincide com outra atividade registrada.',
    AppLanguage.german:
        'Dieser Zeitraum überschneidet sich mit einer anderen erfassten Aktivität.',
  },
  'Hay un horario guardado no válido. Revisa ese registro antes de continuar.':
      {
    AppLanguage.portuguese:
        'Há um horário salvo inválido. Verifique esse registro antes de continuar.',
    AppLanguage.german:
        'Ein gespeicherter Zeitraum ist ungültig. Überprüfe diesen Eintrag, bevor du fortfährst.',
  },
  'Disponible solo durante un período de sueño registrado.': {
    AppLanguage.portuguese:
        'Disponível apenas durante um período de sono registrado.',
    AppLanguage.german:
        'Nur während eines erfassten Schlafzeitraums verfügbar.',
  },
  'Historial del día ({count})': {
    AppLanguage.portuguese: 'Histórico do dia ({count})',
    AppLanguage.german: 'Tagesverlauf ({count})',
  },
  'Todavía no hay registros guardados para este día.': {
    AppLanguage.portuguese: 'Ainda não há registros salvos para este dia.',
    AppLanguage.german: 'Für diesen Tag sind noch keine Einträge gespeichert.',
  },
  'termina al día siguiente': {
    AppLanguage.portuguese: 'termina no dia seguinte',
    AppLanguage.german: 'endet am nächsten Tag',
  },
  'Registra al menos un minuto.': {
    AppLanguage.portuguese: 'Registre pelo menos um minuto.',
    AppLanguage.german: 'Bitte erfasse mindestens eine Minute.',
  },
  'Temporizador': {
    AppLanguage.portuguese: 'Cronômetro',
    AppLanguage.german: 'Timer',
  },
  'Manual': {
    AppLanguage.portuguese: 'Manual',
    AppLanguage.german: 'Manuell',
  },
  'Inicio: {time}': {
    AppLanguage.portuguese: 'Início: {time}',
    AppLanguage.german: 'Start: {time}',
  },
  'Fin: {time}': {
    AppLanguage.portuguese: 'Término: {time}',
    AppLanguage.german: 'Ende: {time}',
  },
  'Iniciar': {
    AppLanguage.portuguese: 'Iniciar',
    AppLanguage.german: 'Starten',
  },
  'Terminar': {
    AppLanguage.portuguese: 'Terminar',
    AppLanguage.german: 'Beenden',
  },
  'Inicio {start} · fin {end}': {
    AppLanguage.portuguese: 'Início {start} · término {end}',
    AppLanguage.german: 'Start {start} · Ende {end}',
  },
  'Duración: {duration}': {
    AppLanguage.portuguese: 'Duração: {duration}',
    AppLanguage.german: 'Dauer: {duration}',
  },
  'Guardar tiempo': {
    AppLanguage.portuguese: 'Salvar tempo',
    AppLanguage.german: 'Zeit speichern',
  },
  'Resultados diarios': {
    AppLanguage.portuguese: 'Resultados diários',
    AppLanguage.german: 'Tagesergebnisse',
  },
  'Todavía no hay registros para este perfil. Añade mediciones desde la pantalla principal.':
      {
    AppLanguage.portuguese:
        'Ainda não há registros para este perfil. Adicione medições na tela principal.',
    AppLanguage.german:
        'Für dieses Profil gibt es noch keine Einträge. Füge Messungen auf der Hauptseite hinzu.',
  },
  'Selecciona un día': {
    AppLanguage.portuguese: 'Selecione um dia',
    AppLanguage.german: 'Wähle einen Tag aus',
  },
  '{count} medición(es)': {
    AppLanguage.portuguese: '{count} medição(ões)',
    AppLanguage.german: '{count} Messung(en)',
  },
  ' · cuestionario guardado': {
    AppLanguage.portuguese: ' · questionário salvo',
    AppLanguage.german: ' · Fragebogen gespeichert',
  },
  '{count} medición(es){questionnaire}': {
    AppLanguage.portuguese: '{count} medição(ões){questionnaire}',
    AppLanguage.german: '{count} Messung(en){questionnaire}',
  },
  '{time} h': {
    AppLanguage.portuguese: '{time} h',
    AppLanguage.german: '{time} Std.',
  },
  '{count} min': {
    AppLanguage.portuguese: '{count} min',
    AppLanguage.german: '{count} Min.',
  },
  'Diagrama · {date}': {
    AppLanguage.portuguese: 'Gráfico · {date}',
    AppLanguage.german: 'Diagramm · {date}',
  },
  'Imprimir o guardar PDF': {
    AppLanguage.portuguese: 'Imprimir ou salvar PDF',
    AppLanguage.german: 'PDF drucken oder speichern',
  },
  'No hay tiempos registrados para este día.': {
    AppLanguage.portuguese: 'Não há tempos registrados para este dia.',
    AppLanguage.german: 'Für diesen Tag wurden keine Zeiten erfasst.',
  },
  'Mediciones guardadas': {
    AppLanguage.portuguese: 'Medições salvas',
    AppLanguage.german: 'Gespeicherte Messungen',
  },
  'Registro de sueño': {
    AppLanguage.portuguese: 'Registro do sono',
    AppLanguage.german: 'Schlafprotokoll',
  },
  'Perfil: {name}': {
    AppLanguage.portuguese: 'Perfil: {name}',
    AppLanguage.german: 'Profil: {name}',
  },
  'Fecha: {date}': {
    AppLanguage.portuguese: 'Data: {date}',
    AppLanguage.german: 'Datum: {date}',
  },
  'Tiempo total por categoría (horas)': {
    AppLanguage.portuguese: 'Tempo total por categoria (horas)',
    AppLanguage.german: 'Gesamtzeit nach Kategorie (Stunden)',
  },
  'Categoría': {
    AppLanguage.portuguese: 'Categoria',
    AppLanguage.german: 'Kategorie',
  },
  'Total': {
    AppLanguage.portuguese: 'Total',
    AppLanguage.german: 'Gesamt',
  },
  'Minutos': {
    AppLanguage.portuguese: 'Minutos',
    AppLanguage.german: 'Minuten',
  },
  'Mediciones': {
    AppLanguage.portuguese: 'Medições',
    AppLanguage.german: 'Messungen',
  },
  'Horario': {
    AppLanguage.portuguese: 'Horário',
    AppLanguage.german: 'Uhrzeit',
  },
  'Duración': {
    AppLanguage.portuguese: 'Duração',
    AppLanguage.german: 'Dauer',
  },
  'No hay mediciones.': {
    AppLanguage.portuguese: 'Não há medições.',
    AppLanguage.german: 'Keine Messungen vorhanden.',
  },
  'Dormir en su propia cama': {
    AppLanguage.portuguese: 'Dormir na própria cama',
    AppLanguage.german: 'Im eigenen Bett schlafen',
  },
  'Dormir en la cama de los padres': {
    AppLanguage.portuguese: 'Dormir na cama dos pais',
    AppLanguage.german: 'Im Bett der Eltern schlafen',
  },
  'Dormir en otro lugar': {
    AppLanguage.portuguese: 'Dormir em outro lugar',
    AppLanguage.german: 'An einem anderen Ort schlafen',
  },
  'Despertarse brevemente durante el sueño (+)': {
    AppLanguage.portuguese: 'Acordar brevemente durante o sono (+)',
    AppLanguage.german: 'Während des Schlafs kurz aufwachen (+)',
  },
  'Despertarse durante mucho tiempo (-)': {
    AppLanguage.portuguese: 'Ficar acordado por muito tempo (-)',
    AppLanguage.german: 'Lange Zeit während des Schlafs wach sein (-)',
  },
  'Rutina nocturna': {
    AppLanguage.portuguese: 'Rotina noturna',
    AppLanguage.german: 'Abendroutine',
  },
  'Ritual para conciliar el sueño': {
    AppLanguage.portuguese: 'Ritual para adormecer',
    AppLanguage.german: 'Einschlafritual',
  },
  'Llanto, llanto desconsolado': {
    AppLanguage.portuguese: 'Choro, choro inconsolável',
    AppLanguage.german: 'Weinen, heftiges Weinen',
  },
  'Lloriqueo, quejas, irritabilidad': {
    AppLanguage.portuguese: 'Choramingo, reclamações, irritabilidade',
    AppLanguage.german: 'Wimmern, Beschwerden, Reizbarkeit',
  },
  'Alegre, descansado/a, de buen humor': {
    AppLanguage.portuguese: 'Alegre, descansado/a, bem-humorado/a',
    AppLanguage.german: 'Fröhlich, ausgeruht, gut gelaunt',
  },
  'Comer, lactar, alimentar': {
    AppLanguage.portuguese: 'Comer, mamar, alimentar',
    AppLanguage.german: 'Essen, stillen, füttern',
  },
  'Llevar en brazos, mecer, pelota de pilates u otros': {
    AppLanguage.portuguese:
        'Pegar no colo, balançar, bola de pilates ou outros',
    AppLanguage.german: 'Tragen, wiegen, Gymnastikball oder anderes',
  },
  'Aplicación de sonidos, secador u otros': {
    AppLanguage.portuguese: 'Aplicativo de sons, secador ou outros',
    AppLanguage.german: 'Geräusche-App, Föhn oder anderes',
  },
  'Juego en solitario': {
    AppLanguage.portuguese: 'Brincar sozinho/a',
    AppLanguage.german: 'Allein spielen',
  },
  'Juego con padres/persona de referencia': {
    AppLanguage.portuguese: 'Brincar com os pais/pessoa de referência',
    AppLanguage.german: 'Mit Eltern/Bezugsperson spielen',
  },
  'Tiempo para mamá': {
    AppLanguage.portuguese: 'Tempo para a mamãe',
    AppLanguage.german: 'Zeit für Mama',
  },
  'Estamos en casa': {
    AppLanguage.portuguese: 'Estamos em casa',
    AppLanguage.german: 'Wir sind zu Hause',
  },
  'Estamos fuera de casa': {
    AppLanguage.portuguese: 'Estamos fora de casa',
    AppLanguage.german: 'Wir sind außer Haus',
  },
};

String appText(
  BuildContext context,
  String text, [
  Map<String, String> values = const {},
]) {
  final language = AppLanguageScope.of(context);
  var translated = _translations[text]?[language] ?? text;
  for (final entry in values.entries) {
    translated = translated.replaceAll('{${entry.key}}', entry.value);
  }
  return translated;
}
