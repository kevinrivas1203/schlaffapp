import 'package:flutter/material.dart';

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({
    super.key,
    required this.childName,
    required this.date,
    required this.initialAnswers,
  });

  final String childName;
  final DateTime date;
  final Map<String, String> initialAnswers;

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  static const _questions = <(String, int)>[
    ('¿A qué hora se despertó hoy?', 1),
    ('¿A qué hora se acostó por la noche?', 1),
    ('¿Cómo fue su estado de ánimo por la noche?', 1),
    ('¿Cómo estaba antes de acostarse?', 1),
    ('Tres momentos bonitos del día', 3),
    ('¿Qué le causó estrés hoy?', 3),
    ('Observaciones adicionales', 3),
  ];

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final (question, _) in _questions)
        question: TextEditingController(
          text: widget.initialAnswers[question] ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop({
      for (final (question, _) in _questions)
        question: _controllers[question]!.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${widget.date.day.toString().padLeft(2, '0')}.'
        '${widget.date.month.toString().padLeft(2, '0')}.'
        '${widget.date.year}';
    return Scaffold(
      appBar: AppBar(title: const Text('Cuestionario diario')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.child_care),
              title: Text(widget.childName),
              subtitle: Text('Fecha del registro: $dateLabel'),
            ),
          ),
          const SizedBox(height: 8),
          ..._questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: _controllers[question.$1],
                minLines: question.$2,
                maxLines: question.$2 + 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: question.$1,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar cuestionario'),
          ),
        ],
      ),
    );
  }
}
