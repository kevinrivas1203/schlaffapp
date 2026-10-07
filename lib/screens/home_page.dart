import 'package:flutter/material.dart';

import '../data/questions.dart';
import '../data/sleep_data.dart';
import '../localization.dart';
import 'questionnaire_page.dart';
import 'results_page.dart';
import 'sleep_timer_page.dart';

class ChildProfilePage extends StatefulWidget {
  const ChildProfilePage({super.key, required this.profile});

  final ChildProfile profile;

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  List<ChildProfile> _profiles = [];
  Map<String, List<SleepDay>> _daysByProfile = {};
  String? _selectedProfileId;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  SleepDay? get _selectedDay {
    final key = dateKeyFor(_selectedDate);
    for (final day in _daysByProfile[_selectedProfileId] ?? <SleepDay>[]) {
      if (day.dateKey == key) return day;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SleepDataStore.loadAll();
    if (!mounted) return;
    setState(() {
      _profiles = data.profiles;
      _daysByProfile = data.days;
      _selectedProfileId = widget.profile.id;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await SleepDataStore.save(_profiles, _daysByProfile);
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _addEntry(String question) async {
    final profile = widget.profile;
    final entry = await Navigator.of(context).push<SleepEntry>(
      MaterialPageRoute(
        builder: (_) => SleepTimerPage(
          question: question,
          historyEntries: List<SleepEntry>.from(_selectedDay?.entries ?? []),
          historyDate: _selectedDate,
        ),
      ),
    );
    if (!mounted || entry == null) return;

    final startMinutes = parseTimeOfDayMinutes(entry.startTime);
    final endMinutes = parseTimeOfDayMinutes(entry.endTime);
    if (startMinutes == null || endMinutes == null) {
      await _showTimelineError(
        SleepTimelineIssue.invalidSavedTime,
        entry,
      );
      return;
    }
    final issue = validateSleepEntryTimeline(
      question: entry.question,
      date: _selectedDate,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      existingDays: _daysByProfile[profile.id] ?? const [],
    );
    if (issue != null) {
      await _showTimelineError(issue, entry);
      return;
    }

    setState(() {
      final days = _daysByProfile.putIfAbsent(profile.id, () => []);
      final key = dateKeyFor(_selectedDate);
      final index = days.indexWhere((day) => day.dateKey == key);
      if (index == -1) {
        days.add(SleepDay(dateKey: key, entries: [entry]));
      } else {
        days[index].entries.add(entry);
      }
      days.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    });
    await _persist();
  }

  String _formatTimelineTime(String value) {
    final minutes = parseTimeOfDayMinutes(value);
    if (minutes == null) return value;
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = switch (AppLanguageScope.of(context)) {
      AppLanguage.spanish => hour < 12 ? 'a. m.' : 'p. m.',
      AppLanguage.portuguese => hour < 12 ? 'AM' : 'PM',
      AppLanguage.german => hour < 12 ? 'AM' : 'PM',
    };
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _showTimelineError(
    SleepTimelineIssue issue,
    SleepEntry attemptedEntry,
  ) async {
    final message = switch (issue) {
      SleepTimelineIssue.wakeOutsideSleep =>
        'El período de despertar debe quedar dentro de un período de sueño registrado.',
      SleepTimelineIssue.overlapsSleep =>
        'Este horario se solapa con un período de sueño.',
      SleepTimelineIssue.overlapsAnotherEntry =>
        'Este horario se solapa con otra actividad registrada.',
      SleepTimelineIssue.invalidSavedTime =>
        'Hay un horario guardado no válido. Revisa ese registro antes de continuar.',
    };
    final attemptedInterval =
        '${_formatTimelineTime(attemptedEntry.startTime)} – '
        '${_formatTimelineTime(attemptedEntry.endTime)}';
    final startMinutes = parseTimeOfDayMinutes(attemptedEntry.startTime);
    final endMinutes = parseTimeOfDayMinutes(attemptedEntry.endTime);
    final conflicts = startMinutes == null || endMinutes == null
        ? <SleepTimelineEntry>[]
        : findSleepTimelineConflicts(
            question: attemptedEntry.question,
            date: _selectedDate,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            existingDays: _daysByProfile[widget.profile.id] ?? const [],
          );
    final conflict = conflicts.firstOrNull;
    final explanation = issue == SleepTimelineIssue.wakeOutsideSleep
        ? appText(
            context,
            'El intervalo de despertar {attempted} debe quedar dentro de un período de sueño registrado.',
            {'attempted': attemptedInterval},
          )
        : conflict == null
            ? appText(context, message)
            : appText(
                context,
                'El intervalo {attempted} se solapa con “{category}”, registrado de {start} a {end}.',
                {
                  'attempted': attemptedInterval,
                  'category': appText(context, conflict.entry.question),
                  'start': _formatTimelineTime(conflict.entry.startTime),
                  'end': _formatTimelineTime(conflict.entry.endTime),
                },
              );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline),
        title: Text(appText(context, 'No se puede guardar este horario')),
        content: Text(explanation),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(appText(context, 'Aceptar')),
          ),
        ],
      ),
    );
  }

  Future<void> _editQuestionnaire() async {
    final profile = widget.profile;
    final savedAnswers = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => QuestionnairePage(
          childName: profile.name,
          date: _selectedDate,
          initialAnswers: Map<String, String>.from(_selectedDay?.answers ?? {}),
        ),
      ),
    );
    if (!mounted || savedAnswers == null) return;

    setState(() {
      final days = _daysByProfile.putIfAbsent(profile.id, () => []);
      final key = dateKeyFor(_selectedDate);
      final index = days.indexWhere((day) => day.dateKey == key);
      if (index == -1) {
        days.add(SleepDay(dateKey: key, answers: savedAnswers));
      } else {
        days[index].answers
          ..clear()
          ..addAll(savedAnswers);
      }
      days.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    });
    await _persist();
  }

  Future<void> _openResults() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ResultsPage(
          profile: widget.profile,
          days: List<SleepDay>.from(
            _daysByProfile[widget.profile.id] ?? [],
          ),
        ),
      ),
    );
  }

  int _totalMinutes(SleepDay? day, String question) {
    if (day == null) return 0;
    return day.totalMinutesFor(question);
  }

  String _formatHours(BuildContext context, int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return appText(context, '{hours} h {minutes} min', {
      'hours': '$hours',
      'minutes': remainder.toString().padLeft(2, '0'),
    });
  }

  @override
  Widget build(BuildContext context) {
    final day = _selectedDay;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        actions: [
          IconButton(
            tooltip: appText(context, 'Resultados e informes'),
            onPressed: _loading ? null : _openResults,
            icon: const Icon(Icons.bar_chart),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _chooseDate,
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}.'
                            '${_selectedDate.month.toString().padLeft(2, '0')}.'
                            '${_selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: _editQuestionnaire,
                        icon: const Icon(Icons.assignment_outlined),
                        label: Text(appText(context, 'Cuestionario')),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      appText(
                        context,
                        'Registro del día · toca una categoría para registrar tiempo',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    children: [
                      ...appQuestions.map((question) {
                        final total = _totalMinutes(day, question);
                        final wakeNeedsSleep = isAwakeningQuestion(question) &&
                            !hasSleepIntervalOnDate(
                              date: _selectedDate,
                              existingDays:
                                  _daysByProfile[widget.profile.id] ?? const [],
                            );
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.schedule),
                            ),
                            title: Text(appText(context, question)),
                            subtitle: Text(wakeNeedsSleep
                                ? appText(
                                    context,
                                    'Disponible solo durante un período de sueño registrado.',
                                  )
                                : total == 0
                                    ? appText(
                                        context,
                                        'Sin tiempo registrado',
                                      )
                                    : appText(
                                        context,
                                        'Total: {time} · {count} registro(s)',
                                        {
                                          'time': _formatHours(
                                            context,
                                            total,
                                          ),
                                          'count':
                                              '${day!.entries.where((e) => e.question == question).length}',
                                        },
                                      )),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: wakeNeedsSleep
                                ? null
                                : () => _addEntry(question),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
