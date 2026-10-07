import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChildProfile {
  const ChildProfile({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class SleepEntry {
  const SleepEntry({
    required this.question,
    required this.minutes,
    required this.startTime,
    required this.endTime,
  });

  final String question;
  final int minutes;
  final String startTime;
  final String endTime;

  Map<String, Object?> toJson() => {
        'question': question,
        'minutes': minutes,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory SleepEntry.fromJson(Map<String, dynamic> json) => SleepEntry(
        question: json['question'] as String,
        minutes: json['minutes'] as int,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
      );
}

class SleepDay {
  SleepDay({
    required this.dateKey,
    List<SleepEntry>? entries,
    Map<String, String>? answers,
  })  : entries = entries ?? [],
        answers = answers ?? {};

  final String dateKey;
  final List<SleepEntry> entries;
  final Map<String, String> answers;

  int totalMinutesFor(String question) => entries
      .where((entry) => entry.question == question)
      .fold<int>(0, (total, entry) => total + entry.minutes);

  Map<String, Object?> toJson() => {
        'dateKey': dateKey,
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'answers': answers,
      };

  factory SleepDay.fromJson(Map<String, dynamic> json) => SleepDay(
        dateKey: json['dateKey'] as String,
        entries: (json['entries'] as List<dynamic>)
            .map((entry) => SleepEntry.fromJson(entry as Map<String, dynamic>))
            .toList(),
        answers: Map<String, String>.from(json['answers'] as Map),
      );
}

enum SleepTimelineIssue {
  wakeOutsideSleep,
  overlapsSleep,
  overlapsAnotherEntry,
  invalidSavedTime,
}

bool isSleepQuestion(String question) => const {
      'Dormir en su propia cama',
      'Dormir en la cama de los padres',
      'Dormir en otro lugar',
    }.contains(question);

bool isAwakeningQuestion(String question) => const {
      'Despertarse brevemente durante el sueño (+)',
      'Despertarse durante mucho tiempo (-)',
    }.contains(question);

SleepTimelineIssue? validateSleepEntryTimeline({
  required String question,
  required DateTime date,
  required int startMinutes,
  required int endMinutes,
  required List<SleepDay> existingDays,
}) {
  final dayStart = _utcDayStart(date);
  final candidateStart = dayStart + startMinutes;
  final candidateEnd =
      dayStart + endMinutes + (endMinutes <= startMinutes ? 1440 : 0);
  final existing = <({int start, int end, String question})>[];

  for (final day in existingDays) {
    final existingDayStart = _parseDateKey(day.dateKey);
    if (existingDayStart == null) continue;
    for (final entry in day.entries) {
      final start = parseTimeOfDayMinutes(entry.startTime);
      final end = parseTimeOfDayMinutes(entry.endTime);
      if (start == null || end == null || end == start) {
        return SleepTimelineIssue.invalidSavedTime;
      }
      final absoluteStart = existingDayStart + start;
      final absoluteEnd = existingDayStart + end + (end <= start ? 1440 : 0);
      existing.add((
        start: absoluteStart,
        end: absoluteEnd,
        question: entry.question,
      ));
    }
  }

  final overlapping = existing
      .where(
          (entry) => candidateStart < entry.end && entry.start < candidateEnd)
      .toList();

  if (isAwakeningQuestion(question)) {
    final containedInSleep = existing.any(
      (entry) =>
          isSleepQuestion(entry.question) &&
          entry.start <= candidateStart &&
          candidateEnd <= entry.end,
    );
    if (!containedInSleep) return SleepTimelineIssue.wakeOutsideSleep;
    if (overlapping.any(
      (entry) =>
          !isSleepQuestion(entry.question) &&
          !isAwakeningQuestion(entry.question),
    )) {
      return SleepTimelineIssue.overlapsAnotherEntry;
    }
    if (overlapping.any((entry) => isAwakeningQuestion(entry.question))) {
      return SleepTimelineIssue.overlapsAnotherEntry;
    }
    return null;
  }

  if (overlapping.any((entry) => isSleepQuestion(entry.question))) {
    return SleepTimelineIssue.overlapsSleep;
  }
  if (overlapping.isNotEmpty) {
    return SleepTimelineIssue.overlapsAnotherEntry;
  }
  return null;
}

bool hasSleepIntervalOnDate({
  required DateTime date,
  required List<SleepDay> existingDays,
}) {
  final dayStart = _utcDayStart(date);
  final dayEnd = dayStart + 1440;
  for (final day in existingDays) {
    final existingDayStart = _parseDateKey(day.dateKey);
    if (existingDayStart == null) continue;
    for (final entry in day.entries) {
      if (!isSleepQuestion(entry.question)) continue;
      final start = parseTimeOfDayMinutes(entry.startTime);
      final end = parseTimeOfDayMinutes(entry.endTime);
      if (start == null || end == null || start == end) continue;
      final absoluteStart = existingDayStart + start;
      final absoluteEnd = existingDayStart + end + (end <= start ? 1440 : 0);
      if (absoluteStart < dayEnd && dayStart < absoluteEnd) return true;
    }
  }
  return false;
}

int _utcDayStart(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerMinute;

int? _parseDateKey(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute;
}

int? parseTimeOfDayMinutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour < 0 || hour > 23) return null;
  if (minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

class SleepDataStore {
  static const _storageKey = 'schlaffapp_local_data_v1';

  static Future<void> save(
    List<ChildProfile> profiles,
    Map<String, List<SleepDay>> daysByProfile,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final data = <String, Object?>{
      'profiles': profiles.map((profile) => profile.toJson()).toList(),
      'days': daysByProfile.map(
        (id, days) => MapEntry(id, days.map((day) => day.toJson()).toList()),
      ),
    };
    await preferences.setString(_storageKey, jsonEncode(data));
  }

  static Future<
          ({List<ChildProfile> profiles, Map<String, List<SleepDay>> days})>
      loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) {
      return (
        profiles: <ChildProfile>[],
        days: <String, List<SleepDay>>{},
      );
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final profiles = (decoded['profiles'] as List<dynamic>)
        .map(
            (profile) => ChildProfile.fromJson(profile as Map<String, dynamic>))
        .toList();
    final rawDays = decoded['days'] as Map<String, dynamic>;
    final days = <String, List<SleepDay>>{};
    rawDays.forEach((profileId, values) {
      days[profileId] = (values as List<dynamic>)
          .map((day) => SleepDay.fromJson(day as Map<String, dynamic>))
          .toList();
    });
    return (profiles: profiles, days: days);
  }
}

String dateKeyFor(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int durationMinutesForInterval(int startMinutes, int endMinutes) {
  final difference = endMinutes - startMinutes;
  return difference < 0 ? difference + 24 * 60 : difference;
}

String totalHoursLabel(int minutes) =>
    (minutes / 60).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
