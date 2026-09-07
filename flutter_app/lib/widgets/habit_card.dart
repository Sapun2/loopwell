import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_icons.dart';
import '../theme/app_theme.dart';

/// One row on the Home screen: icon, name, a short status line, and a
/// tappable completion circle. Tapping the card body opens Habit Detail;
/// tapping the circle toggles today's completion in place without leaving
/// Home (FR2 + FR5).
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
      // Distinguishes the body tap (open details) from the tick circle,
      // which publishes its own node.
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

/// The tick circle. Drawn at 28px to match the Figma card, but wrapped in a
/// 44x44 gesture area so it still clears the WCAG 2.1 AA / NFR minimum
/// touch target — the visual size and the hit size are deliberately
/// different here.
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
      // container: true keeps this out of the enclosing card's merged
      // semantics node, so the tick is exposed as its own control rather
      // than the whole row being announced as one checkbox.
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
