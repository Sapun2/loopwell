import 'habit_icons.dart';

/// yyyy-MM-dd date key used for the completions list and all "same day"
/// comparisons. A hand-rolled string (not DateFormat) so there is zero
/// dependency on locale/ICU data being initialised.
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

  /// yyyy-MM-dd keys, one per day the habit was marked done. Deliberately a
  /// List not a Set so it round-trips through JSON with no extra encoding.
  final List<String> completions;

  final DateTime createdAt;

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  /// Human-readable repeat rule, e.g. "Every day", "Weekdays", "3 days a
  /// week". Used as the habit card subtitle when there is no streak yet,
  /// and on the Habit Detail reminder card.
  String get frequencyLabel {
    final days = weekdays.toSet();
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && days.containsAll(const {1, 2, 3, 4, 5})) return 'Weekdays';
    if (days.length == 2 && days.containsAll(const {6, 7})) return 'Weekends';
    if (days.length == 1) return 'Every ${_weekdayNames[days.first]!}';
    return '${days.length} days a week';
  }

  /// "Monday" for 1 ... "Sunday" for 7. Used for accessibility labels on
  /// the weekday picker and for [frequencyLabel].
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

  /// Consecutive scheduled days, ending today, that were completed. Today
  /// gets a grace period: if it is scheduled but not yet completed, that
  /// does not break the streak (the day is not over yet) — but any earlier
  /// missed scheduled day does.
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

  /// Fraction (0.0-1.0) of scheduled days in the last [days] days
  /// (including today) that were completed. 0 if nothing was scheduled in
  /// range yet (e.g. a habit created minutes ago).
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


  /// The longest run of consecutive scheduled days ever completed. Shown as
  /// "Best" on Habit Detail. Like [currentStreak] this is derived on read,
  /// never persisted — it would go stale the moment a day is un-ticked.
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

  /// Completion rate across the habit's whole life so far, as a percentage
  /// of the days it was actually scheduled on. Shown as "Completion" on
  /// Habit Detail.
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
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
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
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
