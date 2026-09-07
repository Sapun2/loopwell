import 'habit_icons.dart';

/// The yyyy-MM-dd key used for the completions list and all same-day
/// comparisons. Built by hand rather than with DateFormat so it carries no
/// dependency on locale data being initialised.
String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

class Habit {
  Habit({
    required this.id,
    required this.name,
    this.iconKey = HabitIcons.defaultKey,
    this.colorIndex = 0,
    List<int>? weekdays,
    this.reminderHour,
    this.reminderMinute,
    List<String>? completions,
    DateTime? createdAt,
  })  : weekdays = weekdays ?? const [1, 2, 3, 4, 5, 6, 7],
        completions = completions ?? <String>[],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String iconKey;
  int colorIndex;

  /// 1 = Monday .. 7 = Sunday (matches DateTime.weekday). Defaults to every
  /// day.
  List<int> weekdays;

  int? reminderHour;
  int? reminderMinute;

  /// One yyyy-MM-dd key per completed day. A List rather than a Set so it
  /// round-trips through JSON without additional encoding.
  final List<String> completions;

  final DateTime createdAt;

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  /// Human-readable repeat rule, such as "Every day" or "3 days a week".
  String get frequencyLabel {
    final days = weekdays.toSet();
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && days.containsAll(_workDays)) return 'Weekdays';
    if (days.length == 2 && days.containsAll(_weekendDays)) return 'Weekends';
    if (days.length == 1) return 'Every ${_weekdayNames[days.first]!}';
    return '${days.length} days a week';
  }

  static const _workDays = {1, 2, 3, 4, 5};
  static const _weekendDays = {6, 7};

  /// "Monday" for 1 through "Sunday" for 7.
  static String weekdayName(int weekday) => _weekdayNames[weekday] ?? '';

  static const Map<int, String> _weekdayNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  bool isScheduledOn(DateTime date) => weekdays.contains(date.weekday);

  bool isCompletedOn(DateTime date) => completions.contains(dateKey(date));

  void toggleCompletion(DateTime date) {
    final key = dateKey(date);
    if (completions.contains(key)) {
      completions.remove(key);
    } else {
      completions.add(key);
    }
  }

  /// Consecutive completed scheduled days ending today. Today is given a
  /// grace period: if it is scheduled but not yet completed the streak
  /// survives, while any earlier missed scheduled day ends it.
  int get currentStreak {
    var streak = 0;
    final today = startOfDay(DateTime.now());
    var cursor = today;
    final earliest = startOfDay(createdAt);
    while (!cursor.isBefore(earliest)) {
      if (isScheduledOn(cursor)) {
        if (isCompletedOn(cursor)) {
          streak++;
        } else if (cursor.isAtSameMomentAs(today)) {
          // Today not logged yet — skip without breaking the streak.
        } else {
          break;
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Proportion (0.0-1.0) of scheduled days in the last [days] days,
  /// including today, that were completed. Returns 0 when nothing was
  /// scheduled in range.
  double completionRate(int days) {
    final today = startOfDay(DateTime.now());
    final earliest = startOfDay(createdAt);
    var scheduled = 0;
    var done = 0;
    for (var i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(earliest)) continue;
      if (!isScheduledOn(day)) continue;
      scheduled++;
      if (isCompletedOn(day)) done++;
    }
    if (scheduled == 0) return 0;
    return done / scheduled;
  }

  /// The longest run of consecutive completed scheduled days. Like
  /// [currentStreak] this is derived on read rather than persisted, which
  /// would go stale as soon as a day were un-ticked.
  int get bestStreak {
    if (completions.isEmpty) return 0;
    final earliest = startOfDay(createdAt);
    final today = startOfDay(DateTime.now());
    var best = 0;
    var run = 0;
    var cursor = earliest;
    while (!cursor.isAfter(today)) {
      if (isScheduledOn(cursor)) {
        if (isCompletedOn(cursor)) {
          run++;
          if (run > best) best = run;
        } else if (!cursor.isAtSameMomentAs(today)) {
          // Today is still open, so an unticked today does not end the run.
          run = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return best;
  }

  /// Completion rate over the habit's lifetime, as a proportion of the days
  /// it was actually scheduled.
  double get lifetimeCompletionRate {
    final earliest = startOfDay(createdAt);
    final today = startOfDay(DateTime.now());
    final span = today.difference(earliest).inDays + 1;
    return completionRate(span);
  }

  int get totalCompletions => completions.length;

  Habit copyWith({
    String? name,
    String? iconKey,
    int? colorIndex,
    List<int>? weekdays,
    int? reminderHour,
    int? reminderMinute,
    bool clearReminder = false,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorIndex: colorIndex ?? this.colorIndex,
      weekdays: weekdays ?? List<int>.from(this.weekdays),
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute:
          clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      completions: List<String>.from(completions),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'colorIndex': colorIndex,
        'weekdays': weekdays,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'completions': completions,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String? ?? HabitIcons.defaultKey,
        colorIndex: json['colorIndex'] as int? ?? 0,
        weekdays: (json['weekdays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [1, 2, 3, 4, 5, 6, 7],
        reminderHour: json['reminderHour'] as int?,
        reminderMinute: json['reminderMinute'] as int?,
        completions: (json['completions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            <String>[],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
