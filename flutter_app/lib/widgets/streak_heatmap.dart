import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/app_theme.dart';

/// A five-week by seven-day grid, Sunday first, oldest week at the top.
///
/// A filled cell was completed; an outlined cell was scheduled and missed; a
/// faint cell was not scheduled, predates the habit, or is still ahead.
class StreakHeatmap extends StatelessWidget {
  const StreakHeatmap({super.key, required this.habit});

  final Habit habit;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final swatch = AppColors.swatchAt(habit.colorIndex);
    final today = startOfDay(DateTime.now());

    // The grid always ends on the Saturday of the current week so the layout
    // does not reshuffle daily. DateTime.weekday runs 1=Mon..7=Sun, so Sunday
    // maps to column zero.
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

    final dayLabelStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11);

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
                  child: _Cell(
                      date: date, habit: habit, swatch: swatch, today: today),
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
