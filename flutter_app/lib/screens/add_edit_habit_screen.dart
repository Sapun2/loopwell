import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/habit_icons.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/section_label.dart';

enum _Frequency { everyDay, weekdays, custom }

const _everyDay = {1, 2, 3, 4, 5, 6, 7};
const _weekdaysOnly = {1, 2, 3, 4, 5};

/// FR3 (create), FR7 (edit / delete). A single scroll form for name, icon,
/// colour, and frequency, plus FR4's reminder time, with the primary action
/// pinned to the bottom. Sensible defaults are pre-selected so a new habit
/// can be saved with zero decisions if the user just wants to move fast.
/// Laid out against design/screenshots/hifi_3_addedit.png.
class AddEditHabitScreen extends StatefulWidget {
  const AddEditHabitScreen({super.key, this.habitId});

  /// Null when creating a new habit; set when editing an existing one.
  final String? habitId;

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _iconKey;
  late int _colorIndex;
  late Set<int> _weekdays;
  late _Frequency _frequency;
  bool _reminderOn = false;
  TimeOfDay? _reminderTime;

  bool get _isEditing => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    final existing = _isEditing ? context.read<HabitStore>().byId(widget.habitId!) : null;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _iconKey = existing?.iconKey ?? HabitIcons.defaultKey;
    _colorIndex = existing?.colorIndex ?? 0;
    _weekdays = (existing?.weekdays ?? const [1, 2, 3, 4, 5, 6, 7]).toSet();
    _frequency = _frequencyFor(_weekdays);
    _reminderOn = existing?.hasReminder ?? false;
    _reminderTime = (existing != null && existing.hasReminder)
        ? TimeOfDay(hour: existing.reminderHour!, minute: existing.reminderMinute!)
        : null;
  }

  static _Frequency _frequencyFor(Set<int> days) {
    if (setEquals(days, _everyDay)) return _Frequency.everyDay;
    if (setEquals(days, _weekdaysOnly)) return _Frequency.weekdays;
    return _Frequency.custom;
  }

  static bool setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && mounted) setState(() => _reminderTime = picked);
  }

  void _selectFrequency(_Frequency value) {
    setState(() {
      _frequency = value;
      switch (value) {
        case _Frequency.everyDay:
          _weekdays = {..._everyDay};
        case _Frequency.weekdays:
          _weekdays = {..._weekdaysOnly};
        case _Frequency.custom:
          // Keep whatever is already selected so switching to Custom does
          // not silently wipe the user's days.
          break;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day.')),
      );
      return;
    }
    // Turning the reminder on without ever picking a time would otherwise
    // save a reminder of "null" that the UI then renders as Off.
    if (_reminderOn && _reminderTime == null) {
      await _pickTime();
      if (!mounted || _reminderTime == null) return;
    }

    final store = context.read<HabitStore>();
    final navigator = Navigator.of(context);
    final sortedWeekdays = _weekdays.toList()..sort();

    if (_isEditing) {
      final existing = store.byId(widget.habitId!)!;
      final updated = existing.copyWith(
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        colorIndex: _colorIndex,
        weekdays: sortedWeekdays,
        reminderHour: _reminderOn ? _reminderTime?.hour : null,
        reminderMinute: _reminderOn ? _reminderTime?.minute : null,
        clearReminder: !_reminderOn,
      );
      await store.updateHabit(updated);
    } else {
      final habit = Habit(
        id: HabitStore.newId(),
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        colorIndex: _colorIndex,
        weekdays: sortedWeekdays,
        reminderHour: _reminderOn ? _reminderTime?.hour : null,
        reminderMinute: _reminderOn ? _reminderTime?.minute : null,
      );
      await store.addHabit(habit);
    }

    navigator.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'This removes "${_nameController.text.trim()}" and its full history. '
          'This cannot be undone.',
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
    if (confirmed != true || !mounted) return;

    final store = context.read<HabitStore>();
    final navigator = Navigator.of(context);
    await store.deleteHabit(widget.habitId!);
    // Pop back to the shell: the Habit Detail route underneath this one is
    // now showing a habit that no longer exists.
    navigator.popUntil((route) => route.isFirst);
  }

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatch = AppColors.swatchAt(_colorIndex);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Discard',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete habit',
              color: AppColors.error,
              onPressed: _delete,
            ),
          TextButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.md,
            AppSpacing.screenMargin,
            AppSpacing.lg,
          ),
          children: [
            const SectionLabel('Habit name'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'e.g. Drink Water'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Give the habit a name.' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionLabel('Icon'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: HabitIcons.all.entries.map((entry) {
                final selected = entry.key == _iconKey;
                return _TapTarget(
                  onTap: () => setState(() => _iconKey = entry.key),
                  semanticLabel: entry.key,
                  selected: selected,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.tintFor(context, _colorIndex)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: selected ? swatch : theme.dividerColor,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      size: 22,
                      color: selected ? swatch : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionLabel('Colour'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(AppColors.habitSwatches.length, (i) {
                final selected = i == _colorIndex;
                final colour = AppColors.swatchAt(i);
                return _TapTarget(
                  onTap: () => setState(() => _colorIndex = i),
                  semanticLabel: 'Colour ${i + 1}',
                  selected: selected,
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? colour : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionLabel('Frequency'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FrequencyChip(
                  label: 'Every day',
                  selected: _frequency == _Frequency.everyDay,
                  onTap: () => _selectFrequency(_Frequency.everyDay),
                ),
                _FrequencyChip(
                  label: 'Weekdays',
                  selected: _frequency == _Frequency.weekdays,
                  onTap: () => _selectFrequency(_Frequency.weekdays),
                ),
                _FrequencyChip(
                  label: 'Custom',
                  selected: _frequency == _Frequency.custom,
                  onTap: () => _selectFrequency(_Frequency.custom),
                ),
              ],
            ),
            // The Mon..Sun picker only appears under Custom, so the common
            // "every day" case stays a one-tap decision (Figma shows the
            // three presets at rest).
            if (_frequency == _Frequency.custom) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: List.generate(7, (i) {
                  final weekday = i + 1;
                  final selected = _weekdays.contains(weekday);
                  return _TapTarget(
                    semanticLabel: Habit.weekdayName(weekday),
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _weekdays.remove(weekday);
                      } else {
                        _weekdays.add(weekday);
                      }
                      _frequency = _frequencyFor(_weekdays);
                    }),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.primary : theme.colorScheme.surface,
                        border: Border.all(
                          color: selected ? AppColors.primary : theme.dividerColor,
                        ),
                      ),
                      child: Text(
                        _weekdayLabels[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            const SectionLabel('Reminder'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: _reminderOn ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Remind me daily', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          // The time doubles as the button to change it.
                          InkWell(
                            onTap: _reminderOn ? _pickTime : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                !_reminderOn
                                    ? 'Off'
                                    : _reminderTime == null
                                        ? 'Tap to pick a time'
                                        : _reminderTime!.format(context),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _reminderOn
                                      ? AppColors.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: _reminderOn ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _reminderOn,
                      onChanged: (value) {
                        setState(() => _reminderOn = value);
                        if (value && _reminderTime == null) _pickTime();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Pinned rather than the last item in the scroll, so the primary
      // action is always reachable without scrolling on a small screen.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save Changes' : 'Create Habit'),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        // No `alignment` and no fixed width: a Container with alignment set
        // expands to the incoming max width, which stacked the three pills
        // one per row instead of laying them out side by side. The vertical
        // padding is what gets this to the 44pt minimum touch height.
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a small visual control in a >=44x44 gesture area (NFR:
/// accessibility) without changing how big the control itself looks.
class _TapTarget extends StatelessWidget {
  const _TapTarget({
    required this.child,
    required this.onTap,
    required this.selected,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          // widthFactor/heightFactor keep this Align sized to the child. A
          // bare Center expands to the incoming max width instead, which
          // inside a Wrap makes every item full-width and forces one item
          // per row.
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
