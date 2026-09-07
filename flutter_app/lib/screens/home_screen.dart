import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_card.dart';
import '../widgets/progress_ring.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';

/// The daily dashboard: a greeting, a summary of today's progress, and the
/// habit list with one-tap completion.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final now = DateTime.now();
    final today = startOfDay(now);
    final scheduledToday = store.scheduledFor(today);
    final doneToday =
        scheduledToday.where((h) => h.isCompletedOn(today)).length;
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: store.habits.isEmpty
          ? _EmptyState(onAdd: () => _openAdd(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.md,
                AppSpacing.screenMargin,
                // Clearance for the docked action button and navigation bar.
                96,
              ),
              children: [
                Text(
                  '${greetingFor(now)}, ${store.userName.split(' ').first}',
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, d MMMM').format(now),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                _SummaryCard(done: doneToday, total: scheduledToday.length),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today', style: theme.textTheme.titleMedium),
                    Text(
                      '${store.habits.length} ${store.habits.length == 1 ? 'habit' : 'habits'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final habit in store.habits) ...[
                  HabitCard(
                    habit: habit,
                    completedToday: habit.isCompletedOn(today),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => HabitDetailScreen(habitId: habit.id),
                      ),
                    ),
                    onToggle: () => store.toggleCompletion(habit.id, today),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddEditHabitScreen()),
    );
  }
}

/// Progress card at the top of the dashboard. Counts only habits scheduled
/// for today, so a weekday-only habit is not reported as missed on a Sunday.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final remaining = total - done;
    final progress = total == 0 ? 0.0 : done / total;

    final String headline;
    final String support;
    if (total == 0) {
      headline = 'Nothing scheduled today';
      support = 'Enjoy the rest day.';
    } else if (remaining == 0) {
      headline = 'All $total habits done';
      support = "That's the whole day cleared — nice work.";
    } else {
      headline = '$done of $total habits done';
      support = 'Keep going — $remaining left for today';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  support,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ProgressRing(
            value: progress,
            color: Colors.white,
            trackColor: Colors.white.withValues(alpha: 0.28),
            size: 60,
            strokeWidth: 5,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.checklist_rounded,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No habits yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first habit and Loopwell will start tracking\nyour streak from today.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                  onPressed: onAdd, child: const Text('Add a habit')),
            ),
          ],
        ),
      ),
    );
  }
}
