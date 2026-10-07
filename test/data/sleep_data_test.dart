import 'package:flutter_test/flutter_test.dart';
import 'package:protocolschlaff/data/sleep_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// HALLO
void main() {
  group('sleep duration totals', () {
    test('converts 02:00 to 06:00 into four hours', () {
      expect(durationMinutesForInterval(2 * 60, 6 * 60), 240);
      expect(totalHoursLabel(240), '4');
    });

    test('supports intervals that continue after midnight', () {
      expect(durationMinutesForInterval(23 * 60, 1 * 60), 120);
    });

    test('requires brief awakenings to be inside an existing sleep interval',
        () {
      final days = [
        SleepDay(
          dateKey: '2026-10-07',
          entries: const [
            SleepEntry(
              question: 'Dormir en su propia cama',
              minutes: 180,
              startTime: '11:00',
              endTime: '14:00',
            ),
          ],
        ),
      ];

      expect(
        validateSleepEntryTimeline(
          question: 'Despertarse brevemente durante el sueño (+)',
          date: DateTime(2026, 10, 7),
          startMinutes: 15 * 60,
          endMinutes: 15 * 60 + 10,
          existingDays: days,
        ),
        SleepTimelineIssue.wakeOutsideSleep,
      );
      expect(
        validateSleepEntryTimeline(
          question: 'Despertarse brevemente durante el sueño (+)',
          date: DateTime(2026, 10, 7),
          startMinutes: 12 * 60,
          endMinutes: 12 * 60 + 10,
          existingDays: days,
        ),
        isNull,
      );
      expect(
        validateSleepEntryTimeline(
          question: 'Despertarse durante mucho tiempo (-)',
          date: DateTime(2026, 10, 7),
          startMinutes: 12 * 60,
          endMinutes: 13 * 60,
          existingDays: days,
        ),
        isNull,
      );
    });

    test('blocks other activities and overlapping awake intervals', () {
      final sleepDay = SleepDay(
        dateKey: '2026-10-07',
        entries: const [
          SleepEntry(
            question: 'Dormir en su propia cama',
            minutes: 180,
            startTime: '11:00',
            endTime: '14:00',
          ),
        ],
      );
      expect(
        validateSleepEntryTimeline(
          question: 'Juego con padres/persona de referencia',
          date: DateTime(2026, 10, 7),
          startMinutes: 11 * 60 + 30,
          endMinutes: 12 * 60 + 30,
          existingDays: [sleepDay],
        ),
        SleepTimelineIssue.overlapsSleep,
      );

      final awakeDay = SleepDay(
        dateKey: '2026-10-07',
        entries: const [
          SleepEntry(
            question: 'Juego en solitario',
            minutes: 60,
            startTime: '10:00',
            endTime: '11:00',
          ),
        ],
      );
      expect(
        validateSleepEntryTimeline(
          question: 'Tiempo para mamá',
          date: DateTime(2026, 10, 7),
          startMinutes: 10 * 60 + 30,
          endMinutes: 11 * 60 + 30,
          existingDays: [awakeDay],
        ),
        SleepTimelineIssue.overlapsAnotherEntry,
      );
    });

    test('treats end times before start times as next-day intervals', () {
      final previousDay = SleepDay(
        dateKey: '2026-10-07',
        entries: const [
          SleepEntry(
            question: 'Dormir en otro lugar',
            minutes: 720,
            startTime: '18:00',
            endTime: '06:00',
          ),
        ],
      );

      expect(
        hasSleepIntervalOnDate(
          date: DateTime(2026, 10, 8),
          existingDays: [previousDay],
        ),
        isTrue,
      );
      expect(
        validateSleepEntryTimeline(
          question: 'Juego en solitario',
          date: DateTime(2026, 10, 8),
          startMinutes: 60,
          endMinutes: 120,
          existingDays: [previousDay],
        ),
        SleepTimelineIssue.overlapsSleep,
      );
    });

    test('adds multiple measurements of the same category', () {
      final day = SleepDay(
        dateKey: '2026-10-07',
        entries: const [
          SleepEntry(
            question: 'Dormir en la cama',
            minutes: 120,
            startTime: '02:00',
            endTime: '04:00',
          ),
          SleepEntry(
            question: 'Dormir en la cama',
            minutes: 120,
            startTime: '04:00',
            endTime: '06:00',
          ),
        ],
      );

      expect(day.totalMinutesFor('Dormir en la cama'), 240);
      expect(totalHoursLabel(day.totalMinutesFor('Dormir en la cama')), '4');
    });

    test('formats fractional hours without trailing zeroes', () {
      expect(totalHoursLabel(90), '1.5');
    });

    test('persists profiles and daily logs locally', () async {
      SharedPreferences.setMockInitialValues({});
      const profile = ChildProfile(id: 'child-1', name: 'Alex');
      final day = SleepDay(
        dateKey: '2026-10-07',
        entries: const [
          SleepEntry(
            question: 'Dormir en su propia cama',
            minutes: 240,
            startTime: '02:00',
            endTime: '06:00',
          ),
        ],
        answers: const {'Estado de ánimo': 'Tranquilo'},
      );

      await SleepDataStore.save([
        profile
      ], {
        profile.id: [day],
      });
      final loaded = await SleepDataStore.loadAll();

      expect(loaded.profiles.single.name, 'Alex');
      expect(loaded.days[profile.id]!.single.dateKey, '2026-10-07');
      expect(
        loaded.days[profile.id]!.single.totalMinutesFor(
          'Dormir en su propia cama',
        ),
        240,
      );
      expect(
        loaded.days[profile.id]!.single.answers['Estado de ánimo'],
        'Tranquilo',
      );
    });
  });
}
