import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/habit_icons.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_ring.dart';

/// Aggregate statistics across every habit: a weekly completion rate and a
/// per-habit ranking. The dashboard covers today; this covers the week.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final theme = Theme.of(context);
    final today = startOfDay(DateTime.now());
    final habits = store.habits;

    if (habits.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Add a habit and your weekly stats will show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    // Last seven days across every habit, counting only the days each was
    // actually scheduled.
    var scheduled = 0;
    var done = 0;
    for (final habit in habits) {
      final earliest = startOfDay(habit.createdAt);
      for (var i = 0; i < 7; i++) {
        final day = today.subtract(Duration(days: i));
        if (day.isBefore(earliest) || !habit.isScheduledOn(day)) continue;
        scheduled++;
        if (habit.isCompletedOn(day)) done++;
      }
    }
    final weekRate = scheduled == 0 ? 0.0 : done / scheduled;

    final bestHabit = habits.reduce(
      (a, b) => b.currentStreak > a.currentStreak ? b : a,
    );
    final totalCompletions =
        habits.fold<int>(0, (sum, h) => sum + h.totalCompletions);

    final ranked = [...habits]..sort(
        (a, b) => b.lifetimeCompletionRate.compareTo(a.lifetimeCompletionRate),
      );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.md,
          AppSpacing.screenMargin,
          96,
        ),
        children: [
          Text('Stats',
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 26)),
          const SizedBox(height: 2),
          Text('Your last 7 days', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  ProgressRing(
                    value: weekRate,
                    color: AppColors.teal,
                    trackColor: AppColors.teal.withValues(alpha: 0.18),
                    size: 76,
                    strokeWidth: 7,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly completion',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$done of $scheduled scheduled habit-days completed.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  value: '${bestHabit.currentStreak}',
                  label: 'Longest active streak',
                  caption: bestHabit.name,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniStat(
                  value: '$totalCompletions',
                  label: 'Habits logged',
                  caption: 'All time',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('By habit', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final habit in ranked) ...[
            _HabitRateRow(habit: habit),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.value, required this.label, required this.caption});
  final String value;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 26,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodyMedium, maxLines: 2),
            const SizedBox(height: 2),
            Text(
              caption,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitRateRow extends StatelessWidget {
  const _HabitRateRow({required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatch = AppColors.swatchAt(habit.colorIndex);
    final rate = habit.lifetimeCompletionRate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tintFor(context, habit.colorIndex),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Icon(HabitIcons.resolve(habit.iconKey),
                  color: swatch, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 6,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(swatch),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${(rate * 100).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(color: swatch),
            ),
          ],
        ),
      ),
    );
  }
}
