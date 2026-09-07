// Unit tests for the statistics derived from a Habit's completion history.
// These are pure functions over the completions list and need no widget tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:loopwell/models/habit.dart';

/// A habit created [createdDaysAgo] days ago, completed on each of the
/// given day-offsets (0 = today, 1 = yesterday, ...).
Habit habitWith({
  required int createdDaysAgo,
  required List<int> completedOffsets,
  List<int>? weekdays,
}) {
  final now = DateTime.now();
  final habit = Habit(
    id: 'test',
    name: 'Test habit',
    weekdays: weekdays,
    createdAt: now.subtract(Duration(days: createdDaysAgo)),
  );
  for (final offset in completedOffsets) {
    habit.toggleCompletion(now.subtract(Duration(days: offset)));
  }
  return habit;
}

void main() {
  group('dateKey', () {
    test('zero-pads month and day', () {
      expect(dateKey(DateTime(2026, 3, 7)), '2026-03-07');
    });
  });

  group('currentStreak', () {
    test('is zero for a habit with no completions', () {
      expect(
          habitWith(createdDaysAgo: 5, completedOffsets: []).currentStreak, 0);
    });

    test('counts consecutive completed days up to today', () {
      expect(
        habitWith(createdDaysAgo: 10, completedOffsets: [0, 1, 2])
            .currentStreak,
        3,
      );
    });

    test('an unlogged today does not break the streak', () {
      // The day is not over, so the preceding run still stands.
      expect(
        habitWith(createdDaysAgo: 10, completedOffsets: [1, 2, 3])
            .currentStreak,
        3,
      );
    });

    test('a missed earlier day does break the streak', () {
      expect(
        habitWith(createdDaysAgo: 10, completedOffsets: [0, 1, 3, 4])
            .currentStreak,
        2,
      );
    });
  });

  group('bestStreak', () {
    test('is zero with no completions', () {
      expect(habitWith(createdDaysAgo: 5, completedOffsets: []).bestStreak, 0);
    });

    test('finds the longest historical run, not just the current one', () {
      // A four-day run last week and a two-day run now.
      final habit = habitWith(
        createdDaysAgo: 20,
        completedOffsets: [0, 1, 7, 8, 9, 10],
      );
      expect(habit.bestStreak, 4);
      expect(habit.currentStreak, 2);
    });
  });

  group('completionRate', () {
    test('is 1.0 when every scheduled day in range was completed', () {
      final habit =
          habitWith(createdDaysAgo: 6, completedOffsets: [0, 1, 2, 3, 4, 5, 6]);
      expect(habit.completionRate(7), 1.0);
    });

    test('ignores days before the habit existed', () {
      // Created two days ago with both days completed: 100%, not 3/30.
      final habit = habitWith(createdDaysAgo: 2, completedOffsets: [0, 1, 2]);
      expect(habit.completionRate(30), 1.0);
    });

    test('is zero when nothing is scheduled in range', () {
      // Sundays only and created today, so nothing scheduled has elapsed
      // unless today is itself a Sunday.
      final habit = habitWith(
          createdDaysAgo: 0, completedOffsets: [], weekdays: const [7]);
      if (DateTime.now().weekday != DateTime.sunday) {
        expect(habit.completionRate(7), 0.0);
      }
    });
  });

  group('frequencyLabel', () {
    test('names the common presets', () {
      expect(habitWith(createdDaysAgo: 1, completedOffsets: []).frequencyLabel,
          'Every day');
      expect(
        habitWith(
            createdDaysAgo: 1,
            completedOffsets: [],
            weekdays: const [1, 2, 3, 4, 5]).frequencyLabel,
        'Weekdays',
      );
      expect(
        habitWith(
            createdDaysAgo: 1,
            completedOffsets: [],
            weekdays: const [6, 7]).frequencyLabel,
        'Weekends',
      );
      expect(
        habitWith(
            createdDaysAgo: 1,
            completedOffsets: [],
            weekdays: const [1, 3, 5]).frequencyLabel,
        '3 days a week',
      );
    });
  });

  group('json round-trip', () {
    test('preserves every field', () {
      final original = Habit(
        id: 'abc',
        name: 'Read',
        iconKey: 'book',
        colorIndex: 3,
        weekdays: const [1, 3, 5],
        reminderHour: 7,
        reminderMinute: 30,
        completions: const ['2026-01-01'],
        createdAt: DateTime(2026, 1, 1),
      );
      final restored = Habit.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.iconKey, original.iconKey);
      expect(restored.colorIndex, original.colorIndex);
      expect(restored.weekdays, original.weekdays);
      expect(restored.reminderHour, 7);
      expect(restored.reminderMinute, 30);
      expect(restored.completions, original.completions);
      expect(restored.createdAt, original.createdAt);
    });

    test('falls back to safe defaults on a partial record', () {
      final restored = Habit.fromJson({'id': 'x', 'name': 'Y'});
      expect(restored.weekdays, [1, 2, 3, 4, 5, 6, 7]);
      expect(restored.completions, isEmpty);
      expect(restored.hasReminder, isFalse);
    });
  });

  group('copyWith', () {
    test('clearReminder drops both halves of the reminder', () {
      final habit =
          Habit(id: 'a', name: 'A', reminderHour: 8, reminderMinute: 0);
      final cleared = habit.copyWith(clearReminder: true);
      expect(cleared.reminderHour, isNull);
      expect(cleared.reminderMinute, isNull);
      expect(cleared.hasReminder, isFalse);
    });

    test('copies the completions list rather than sharing it', () {
      final habit = habitWith(createdDaysAgo: 3, completedOffsets: [0]);
      final copy = habit.copyWith(name: 'Renamed');
      copy.toggleCompletion(DateTime.now().subtract(const Duration(days: 1)));
      expect(habit.completions.length, 1);
      expect(copy.completions.length, 2);
    });
  });
}
