import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/section_label.dart';

/// On-device profile: an editable display name and lifetime totals. There is
/// no account system, so nothing here leaves the device.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final theme = Theme.of(context);
    final today = startOfDay(DateTime.now());

    final habits = store.habits;
    final totalCompletions =
        habits.fold<int>(0, (sum, h) => sum + h.totalCompletions);
    final bestEver = habits.isEmpty
        ? 0
        : habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
    final doneToday = store.doneOn(today);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.md,
          AppSpacing.screenMargin,
          AppSpacing.xl,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    store.userInitials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(store.userName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  'Member since ${DateFormat('d MMMM yyyy').format(store.memberSince)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () => _editName(context, store.userName),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(180, 44),
                  ),
                  child: const Text('Edit name'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionLabel('Lifetime'),
          Row(
            children: [
              Expanded(
                  child: _Tile(value: '${habits.length}', label: 'Habits')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child:
                      _Tile(value: '$totalCompletions', label: 'Completions')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Tile(value: '$bestEver', label: 'Best streak')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Today'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      doneToday == 0
                          ? 'Nothing logged yet today.'
                          : '$doneToday ${doneToday == 1 ? 'habit' : 'habits'} logged today.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loopwell keeps everything on this device. There is no account to '
            'sign in to and nothing is uploaded anywhere.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final store = context.read<HabitStore>();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await store.setUserName(name);
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Column(
          children: [
            FittedBox(
              child: Text(
                value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
