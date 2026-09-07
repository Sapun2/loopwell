import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/app_theme.dart';

/// A 5-week x 7-day grid, Sunday first (matching the S M T W T F S header in
/// design/screenshots/hifi_4_detail.png), oldest week at the top.
///
/// Filled in the habit colour = completed. Faint filled = a day the habit
/// was not scheduled, was before the habit existed, or is still ahead.
/// Outlined in the habit colour = scheduled and missed.
class StreakHeatmap extends StatelessWidget {
  const StreakHeatmap({super.key, required this.habit});

  final Habit habit;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final swatch = AppColors.swatchAt(habit.colorIndex);
    final today = startOfDay(DateTime.now());

    // Always end the grid on the Saturday of the current week, so the
    // layout is stable and does not reshuffle day to day. DateTime.weekday
    // is 1=Mon..7=Sun, so Sunday needs to map to column 0.
    final columnOfToday = today.weekday % 7;
    final endOfThisWeek = today.add(Duration(days: 6 - columnOfToday));
    final gridStart = endOfThisWeek.subtract(const Duration(days: 34));

    final weeks = List.generate(
      5,
      (week) => List.generate(
        7,
        (day) => gridStart.add(Duration(days: week * 7 + day)),
      ),
    );

    final dayLabelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _dayLabels.length; i++)
              Expanded(
                child: Center(child: Text(_dayLabels[i], style: dayLabelStyle)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final week in weeks)
          Row(
            children: [
              for (final date in week)
                Expanded(
                  child: _Cell(date: date, habit: habit, swatch: swatch, today: today),
                ),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.date,
    required this.habit,
    required this.swatch,
    required this.today,
  });

  final DateTime date;
  final Habit habit;
  final Color swatch;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactive = theme.brightness == Brightness.dark
        ? theme.dividerColor
        : theme.dividerColor.withValues(alpha: 0.6);

    final beforeStart = date.isBefore(startOfDay(habit.createdAt));
    final isFuture = date.isAfter(today);
    final scheduled = habit.isScheduledOn(date);
    final completed = habit.isCompletedOn(date);

    final Color fill;
    final Border? outline;
    final String state;
    if (completed) {
      fill = swatch;
      outline = null;
      state = 'done';
    } else if (beforeStart || isFuture || !scheduled) {
      fill = inactive;
      outline = null;
      state = beforeStart || isFuture ? 'not tracked' : 'not scheduled';
    } else {
      fill = Colors.transparent;
      outline = Border.all(color: swatch.withValues(alpha: 0.55), width: 1.5);
      state = 'missed';
    }

    return Semantics(
      label: '${date.day}/${date.month}: $state',
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: outline,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
