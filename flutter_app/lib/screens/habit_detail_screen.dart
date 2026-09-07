import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/habit_icons.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_heatmap.dart';
import 'add_edit_habit_screen.dart';

/// FR6. Streak, completion rate, and total completions alongside a 5-week
/// heat map, so the trend is visible at a glance rather than just today's
/// status. Laid out against design/screenshots/hifi_4_detail.png.
class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final habit = store.byId(habitId);

    if (habit == null) {
      // The habit was deleted (e.g. from the edit screen) while this route
      // was still on the stack below it — bail out quietly rather than
      // crashing on a null lookup; the pop from delete already handles
      // returning to Home.
      return const Scaffold(body: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    final swatch = AppColors.swatchAt(habit.colorIndex);
    final tint = AppColors.tintFor(context, habit.colorIndex);
    final today = startOfDay(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HabitIcons.resolve(habit.iconKey), color: swatch, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                habit.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit habit',
            onPressed: () => _openEdit(context, habit.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.sm,
          AppSpacing.screenMargin,
          AppSpacing.xl,
        ),
        children: [
          // Hero streak card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Icon(HabitIcons.resolve(habit.iconKey), color: swatch, size: 28),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${habit.currentStreak}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  habit.currentStreak == 0
                      ? 'no streak yet — today is a fresh start'
                      : 'day streak — keep it up!',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Three stats with hairline dividers between, as in the Figma.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _Stat(value: '${habit.bestStreak}', label: 'Best')),
                VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
                Expanded(
                  child: _Stat(
                    value: '${(habit.lifetimeCompletionRate * 100).round()}%',
                    label: 'Completion',
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
                Expanded(child: _Stat(value: '${habit.totalCompletions}', label: 'Total')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Last 5 Weeks', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          StreakHeatmap(habit: habit),
          const SizedBox(height: AppSpacing.lg),

          // Today's completion, so Detail is not read-only — FR5 works from
          // here as well as from Home.
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: Icon(
                habit.isCompletedOn(today) ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: habit.isCompletedOn(today)
                    ? AppColors.teal
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                habit.isCompletedOn(today) ? 'Done today' : 'Not done today',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                habit.isScheduledOn(today)
                    ? 'Tap to ${habit.isCompletedOn(today) ? 'undo' : 'mark complete'}'
                    : 'Not scheduled today — tap to log it anyway',
              ),
              onTap: () => store.toggleCompletion(habit.id, today),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: Icon(
                Icons.notifications_none_rounded,
                color: habit.hasReminder
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                habit.hasReminder ? 'Daily reminder' : 'No reminder set',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                habit.hasReminder
                    ? '${TimeOfDay(hour: habit.reminderHour!, minute: habit.reminderMinute!).format(context)} · ${habit.frequencyLabel}'
                    : habit.frequencyLabel,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openEdit(context, habit.id),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          OutlinedButton(
            onPressed: () => _openEdit(context, habit.id),
            child: const Text('Edit Habit'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => _confirmDelete(context, habit),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Delete Habit'),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AddEditHabitScreen(habitId: id)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Habit habit) async {
    final store = context.read<HabitStore>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'This removes "${habit.name}" and its full history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await store.deleteHabit(habit.id);
    navigator.popUntil((route) => route.isFirst);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          child: Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}
