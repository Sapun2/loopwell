import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/habit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/section_label.dart';
import '../widgets/settings_tile.dart';
import 'profile_screen.dart';

/// Application preferences: notifications, appearance, data export and
/// profile.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final theme = Theme.of(context);

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
          Text('Settings',
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 26)),
          const SizedBox(height: AppSpacing.md),
          _ProfileCard(
            initials: store.userInitials,
            name: store.userName,
            memberSince: store.memberSince,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Preferences'),
          SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: store.notificationsEnabled
                ? 'Reminders & daily summary'
                : 'Turned off',
            trailing: Switch(
              value: store.notificationsEnabled,
              onChanged: (value) =>
                  context.read<HabitStore>().setNotificationsEnabled(value),
            ),
            onTap: () => context
                .read<HabitStore>()
                .setNotificationsEnabled(!store.notificationsEnabled),
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsTile(
            icon: Icons.wb_sunny_outlined,
            title: 'Appearance',
            subtitle: _modeLabel(store.themeMode),
            onTap: () => _showThemeSheet(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsTile(
            icon: Icons.download_outlined,
            title: 'Data & Export',
            subtitle: 'Download your habit history',
            onTap: () => _showExportDialog(context, store),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Support'),
          SettingsTile(
            icon: Icons.menu_book_outlined,
            title: 'About Loopwell',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsTile(
            icon: Icons.bar_chart_rounded,
            title: 'Send Feedback',
            onTap: () => _showFeedback(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: TextButton(
              onPressed: () => _confirmSignOut(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }

  static String _modeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        // Watched inside the sheet so the selection tracks the store while
        // the app re-themes underneath it.
        final store = sheetContext.watch<HabitStore>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Appearance',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              // RadioListTile's own groupValue/onChanged pair is deprecated
              // in favour of RadioGroup.
              RadioGroup<ThemeMode>(
                groupValue: store.themeMode,
                onChanged: (value) {
                  if (value == null) return;
                  sheetContext.read<HabitStore>().setThemeMode(value);
                  // Commit and dismiss; the new theme is applied behind the
                  // sheet immediately.
                  Navigator.of(sheetContext).pop();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in ThemeMode.values)
                      RadioListTile<ThemeMode>(
                        value: mode,
                        title: Text(_modeLabel(mode)),
                        subtitle: mode == ThemeMode.system
                            ? const Text('Follow the device setting')
                            : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  void _showExportDialog(BuildContext context, HabitStore store) {
    final json = store.exportJson();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Data & Export'),
        content: SizedBox(
          width: double.maxFinite,
          // Capped so a long export scrolls inside the dialog rather than
          // overflowing it on a short screen.
          height: MediaQuery.of(dialogContext).size.height * 0.45,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 11, height: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Habit data copied to clipboard.')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Loopwell',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.all_inclusive_rounded,
          color: AppColors.primary, size: 40),
      applicationLegalese: '© 2026 Pradeep Bhandari',
      children: const [
        SizedBox(height: AppSpacing.md),
        Text(
          'Small steps, every day. Loopwell is a daily habit tracker that '
          'logs a habit in one tap and never punishes a missed day.\n\n'
          'Your habits are stored only on this device — there is no account '
          'and nothing is uploaded.',
        ),
      ],
    );
  }

  void _showFeedback(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text(
          'Loopwell runs entirely on your device and has no backend, so there '
          'is nowhere to send feedback from inside the app yet. In-app '
          'feedback is planned for a future release.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Loopwell has no account system — this returns you to the welcome '
          'screens. Your habits stay saved on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Flip the flag and unwind to the root route; the gate in
              // main.dart swaps onboarding back in. Pushing onboarding here
              // and clearing the stack would strand the user, because
              // completing it could never swap the shell back.
              context.read<HabitStore>().resetOnboarding();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.initials,
    required this.name,
    required this.memberSince,
    required this.onTap,
  });

  final String initials;
  final String name;
  final DateTime memberSince;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Member since ${DateFormat('MMM yyyy').format(memberSince)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
