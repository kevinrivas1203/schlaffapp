import 'package:flutter/material.dart';

import '../data/questions.dart';
import '../data/sleep_data.dart';
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
        builder: (_) => SleepTimerPage(question: question),
      ),
    );
    if (!mounted || entry == null) return;

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

  String _formatHours(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return '$hours h ${remainder.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    final day = _selectedDay;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        actions: [
          IconButton(
            tooltip: 'Resultados e informes',
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
                            label: const Text('Cuestionario'),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Registro del día · toca una categoría para registrar tiempo',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        itemCount: appQuestions.length,
                        itemBuilder: (context, index) {
                          final question = appQuestions[index];
                          final total = _totalMinutes(day, question);
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.schedule),
                              ),
                              title: Text(question),
                              subtitle: Text(
                                total == 0
                                    ? 'Sin tiempo registrado'
                                    : 'Total: ${_formatHours(total)} · '
                                        '${day!.entries.where((e) => e.question == question).length} registro(s)',
                              ),
                              trailing: const Icon(Icons.add_circle_outline),
                              onTap: () => _addEntry(question),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
