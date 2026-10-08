# Arquitectura y flujos

## Navegación

1. `main.dart` inicia `MyApp`.
2. `app.dart` crea la aplicación, instala las localizaciones Material y muestra
   `ChildProfilesPage`.
3. `ChildProfilesPage` carga y gestiona los perfiles. Al abrir uno, navega a
   `ChildProfilePage`, definido en `home_page.dart`.
4. `ChildProfilePage` permite elegir la fecha y abrir el cuestionario o los
   resultados. Las categorías de `data/questions.dart` abren
   `SleepTimerPage`.

## Registro y edición de mediciones

`SleepTimerPage` recibe la categoría y una copia de las mediciones del día.
Permite medir con el cronómetro o elegir manualmente el comienzo y el final.
Las filas del historial cargan una medición para editarla. Al guardar, devuelve
`SleepEntrySaveResult`: la medición nueva y, si es una edición, el índice de la
medición original.

`ChildProfilePage` valida el intervalo antes de guardar. Si se está editando,
excluye temporalmente la entrada original de la validación, para que no entre en
conflicto consigo misma. Después reemplaza esa entrada o agrega una nueva y
persiste el estado.

## Reglas de horarios

Las funciones de línea de tiempo viven en `data/sleep_data.dart` y trabajan con
fechas normalizadas a medianoche UTC para comparar días adyacentes:

- Un intervalo cuya hora final es anterior o igual a la inicial termina al día
  siguiente.
- Una actividad no puede solaparse con un intervalo de sueño ni con otra
  actividad.
- Los despertares deben quedar completamente dentro de un intervalo de sueño y
  no solaparse con otras entradas de vigilia.
- Las horas se almacenan en formato `HH:mm`; la duración se expresa en minutos.

`SleepTimelineIssue` identifica el motivo de rechazo. La pantalla diaria lo
convierte en un mensaje localizado y muestra, cuando existe, el intervalo que
entra en conflicto.

## Modelo y persistencia

- `ChildProfile`: identificador y nombre.
- `SleepDay`: fecha (`yyyy-MM-dd`), lista de mediciones y respuestas.
- `SleepEntry`: categoría, duración en minutos y horas de inicio y fin.

`SleepDataStore.loadAll()` lee todos los perfiles y días, y `save()` serializa
el conjunto completo en la clave local `schlaffapp_local_data_v1`. Las pantallas
actualizan el estado en memoria y llaman a `save()` después de los cambios.

## Cuestionario y resultados

`QuestionnairePage` inicializa campos de texto a partir de las respuestas del
día y devuelve el mapa actualizado al guardar. Las respuestas se asocian al
mismo `SleepDay` que las mediciones.

`ResultsPage` agrega duraciones por categoría. `_buildPdf` crea el documento con
resumen, mediciones y respuestas del cuestionario. `_viewPdf` presenta ese
documento con `PdfPreview`; la acción `PdfShareAction` comparte el archivo
mediante el selector nativo de las aplicaciones disponibles.

## Idiomas

`localization.dart` define los idiomas soportados y el mapa de traducciones.
`appText(context, texto, parámetros)` busca la traducción para el idioma activo
y sustituye los parámetros. Al añadir texto visible en la interfaz, se debe
añadir su traducción portuguesa y alemana en el mismo archivo.

## Pruebas

- `test/data/sleep_data_test.dart`: duraciones, medianoche, reglas de
  solapamiento, despertares y persistencia.
- `test/widget_test.dart`: navegación, perfiles, cambio de idioma, captura
  manual, historial y edición, y apertura de la vista previa del PDF.

Ejecutar `flutter analyze` y `flutter test` desde la raíz del módulo después de
los cambios.

## Alcance actual

Los datos son locales al dispositivo y no se sincronizan con otras personas o
dispositivos. Las reglas temporales describen restricciones de registro, no
recomendaciones médicas. Las futuras funciones de cuentas y sincronización
están recogidas en `PENDIENTES.md`.
