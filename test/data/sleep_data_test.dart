import 'package:flutter_test/flutter_test.dart';
import 'package:protocolschlaff/data/sleep_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('sleep duration totals', () {
    test('converts 02:00 to 06:00 into four hours', () {
      expect(durationMinutesForInterval(2 * 60, 6 * 60), 240);
      expect(totalHoursLabel(240), '4');
    });

    test('supports intervals that continue after midnight', () {
      expect(durationMinutesForInterval(23 * 60, 1 * 60), 120);
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
