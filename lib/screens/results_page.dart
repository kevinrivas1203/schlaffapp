import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/questions.dart';
import '../data/sleep_data.dart';
import '../localization.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, required this.profile, required this.days});

  final ChildProfile profile;
  final List<SleepDay> days;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  SleepDay? _selectedDay;

  @override
  void initState() {
    super.initState();
    if (widget.days.isNotEmpty) _selectedDay = widget.days.first;
  }

  Map<String, int> _totals(SleepDay day) {
    return {
      for (final question in appQuestions)
        if (day.totalMinutesFor(question) > 0)
          question: day.totalMinutesFor(question),
    };
  }

  String _hoursLabel(BuildContext context, int minutes) =>
      appText(context, '{time} h', {'time': totalHoursLabel(minutes)});

  String _dateLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return key;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  Future<void> _exportPdf(SleepDay day) async {
    final document = pw.Document();
    final totals = _totals(day);
    final rows = appQuestions
        .where((question) => (totals[question] ?? 0) > 0)
        .map(
          (question) => [
            appText(context, question),
            _hoursLabel(context, totals[question]!),
            appText(context, '{count} min', {
              'count': '${totals[question]}',
            }),
          ],
        )
        .toList();
    final detailedEntries = day.entries
        .map(
          (entry) => [
            appText(context, entry.question),
            '${entry.startTime} - ${entry.endTime}',
            _hoursLabel(context, entry.minutes),
          ],
        )
        .toList();
    final answers = day.answers.entries
        .where((answer) => answer.value.trim().isNotEmpty)
        .map((answer) => '${appText(context, answer.key)}\n${answer.value}')
        .join('\n\n');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            appText(context, 'Registro de sueño'),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            appText(context, 'Perfil: {name}', {'name': widget.profile.name}),
          ),
          pw.Text(
            appText(context, 'Fecha: {date}', {
              'date': _dateLabel(day.dateKey),
            }),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            appText(context, 'Tiempo total por categoría (horas)'),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (rows.isEmpty)
            pw.Text(
                appText(context, 'No hay tiempos registrados para este día.'))
          else
            pw.TableHelper.fromTextArray(
              headers: [
                appText(context, 'Categoría'),
                appText(context, 'Total'),
                appText(context, 'Minutos'),
              ],
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE8EEF9),
              ),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            appText(context, 'Mediciones'),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (detailedEntries.isEmpty)
            pw.Text(appText(context, 'No hay mediciones.'))
          else
            pw.TableHelper.fromTextArray(
              headers: [
                appText(context, 'Categoría'),
                appText(context, 'Horario'),
                appText(context, 'Duración'),
              ],
              data: detailedEntries,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE8EEF9),
              ),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          if (answers.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              appText(context, 'Cuestionario'),
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(answers),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => document.save(),
      name: 'registro-${widget.profile.name}-${day.dateKey}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay;
    final totals = selected == null ? <String, int>{} : _totals(selected);
    final maxMinutes = totals.values.fold<int>(0, (max, value) {
      return value > max ? value : max;
    });
    return Scaffold(
      appBar: AppBar(title: Text(appText(context, 'Resultados diarios'))),
      body: widget.days.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  appText(
                    context,
                    'Todavía no hay registros para este perfil. Añade mediciones desde la pantalla principal.',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  appText(context, 'Selecciona un día'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                ...widget.days.map(
                  (day) => Card(
                    child: ListTile(
                      selected: selected?.dateKey == day.dateKey,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_dateLabel(day.dateKey)),
                      subtitle: Text(
                        appText(
                          context,
                          '{count} medición(es){questionnaire}',
                          {
                            'count': '${day.entries.length}',
                            'questionnaire': day.answers.isEmpty
                                ? ''
                                : appText(context, ' · cuestionario guardado'),
                          },
                        ),
                      ),
                      trailing: selected?.dateKey == day.dateKey
                          ? const Icon(Icons.check_circle)
                          : null,
                      onTap: () => setState(() => _selectedDay = day),
                    ),
                  ),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appText(context, 'Diagrama · {date}', {
                            'date': _dateLabel(selected.dateKey),
                          }),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: appText(context, 'Imprimir o guardar PDF'),
                        onPressed: () => _exportPdf(selected),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (totals.isEmpty)
                    Text(appText(
                        context, 'No hay tiempos registrados para este día.'))
                  else
                    ...appQuestions
                        .where((question) => totals.containsKey(question))
                        .map((question) {
                      final minutes = totals[question]!;
                      final fraction =
                          maxMinutes == 0 ? 0.0 : minutes / maxMinutes;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text(appText(context, question))),
                                Text(
                                  _hoursLabel(context, minutes),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 12,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 28),
                  Text(
                    appText(context, 'Mediciones guardadas'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ...selected.entries.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(appText(context, entry.question)),
                      subtitle: Text(
                        '${entry.startTime} - ${entry.endTime}',
                      ),
                      trailing: Text(_hoursLabel(context, entry.minutes)),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
