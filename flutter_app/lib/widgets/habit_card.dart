import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_icons.dart';
import '../theme/app_theme.dart';

/// A habit row: icon, name, status line and a completion control. Tapping
/// the body opens the habit's detail; tapping the circle toggles today's
/// completion without leaving the list.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.completedToday,
    required this.onTap,
    required this.onToggle,
  });

  final Habit habit;
  final bool completedToday;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  String _subtitle() {
    final streak = habit.currentStreak;
    if (streak > 0) return '$streak day streak';
    if (habit.hasReminder) {
      final h = habit.reminderHour!;
      final m = habit.reminderMinute!.toString().padLeft(2, '0');
      final suffix = h < 12 ? 'AM' : 'PM';
      final hour12 = h % 12 == 0 ? 12 : h % 12;
      return 'Reminder at $hour12:$m $suffix';
    }
    return habit.frequencyLabel;
  }

  @override
  Widget build(BuildContext context) {
    final swatch = AppColors.swatchAt(habit.colorIndex);
    final tint = AppColors.tintFor(context, habit.colorIndex);
    final theme = Theme.of(context);

    return Semantics(
      // Distinguishes the body tap from the completion circle, which
      // publishes its own node.
      onTapHint: 'open ${habit.name} details',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Icon(HabitIcons.resolve(habit.iconKey),
                      color: swatch, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CompletionCircle(
                  completed: completedToday,
                  onTap: onToggle,
                  semanticLabel: completedToday
                      ? 'Mark ${habit.name} as not done today'
                      : 'Mark ${habit.name} as done today',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The completion control. Painted at 28px but wrapped in a 44x44 gesture
/// area to meet the minimum touch target; the painted and hit sizes differ
/// deliberately.
class CompletionCircle extends StatelessWidget {
  const CompletionCircle({
    super.key,
    required this.completed,
    required this.onTap,
    this.semanticLabel,
    this.diameter = 28,
  });

  final bool completed;
  final VoidCallback onTap;
  final String? semanticLabel;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).dividerColor;

    return Semantics(
      // Keeps this out of the card's merged semantics node so it is exposed
      // as its own control, rather than the whole row reading as a checkbox.
      container: true,
      button: true,
      checked: completed,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: diameter,
              height: diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? AppColors.teal : Colors.transparent,
                border: Border.all(
                  color: completed ? AppColors.teal : border,
                  width: 2,
                ),
              ),
              child: completed
                  ? Icon(Icons.check_rounded,
                      color: Colors.white, size: diameter * 0.62)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
