import 'package:flutter/material.dart';

class QuestionnaireForm extends StatelessWidget {
  const QuestionnaireForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fragebogen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildField('Name des Kindes'),
            const SizedBox(height: 12),
            _buildField('Datum'),
            const SizedBox(height: 12),
            _buildField('Heute aufgewacht um'),
            const SizedBox(height: 12),
            _buildField('Abendliche Zubettgeh-Zeit'),
            const SizedBox(height: 12),
            _buildField('Stimmung am Abend'),
            const SizedBox(height: 12),
            _buildField('Stimmung vor dem Zubettgehen'),
            const SizedBox(height: 12),
            _buildField('Drei schöne Momente des Tages'),
            const SizedBox(height: 12),
            _buildField('Was hat dich heute gestresst?'),
            const SizedBox(height: 12),
            _buildField('Sonstiges'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
