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
  }) : entries = entries ?? [],
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
        (id, days) =>
            MapEntry(id, days.map((day) => day.toJson()).toList()),
      ),
    };
    await preferences.setString(_storageKey, jsonEncode(data));
  }

  static Future<({List<ChildProfile> profiles, Map<String, List<SleepDay>> days})>
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
        .map((profile) => ChildProfile.fromJson(profile as Map<String, dynamic>))
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

String dateKeyFor(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int durationMinutesForInterval(int startMinutes, int endMinutes) {
  final difference = endMinutes - startMinutes;
  return difference < 0 ? difference + 24 * 60 : difference;
}

String totalHoursLabel(int minutes) => (minutes / 60)
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'\.?0+$'), '');
