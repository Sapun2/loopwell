import 'package:flutter/material.dart';

import '../screens/add_edit_habit_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../theme/app_theme.dart';

/// The persistent chrome around the four top-level destinations: a bottom
/// navigation bar with a docked "+" button in the middle, exactly as in the
/// Figma Home and Settings frames.
///
/// An [IndexedStack] is used rather than swapping the child outright so each
/// tab keeps its own scroll position when you come back to it — switching
/// tabs and losing your place halfway down a habit list reads as a bug.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  static const _destinations = <_Destination>[
    _Destination(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Today'),
    _Destination(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Stats'),
    _Destination(icon: Icons.wb_sunny_outlined, activeIcon: Icons.wb_sunny_rounded, label: 'Settings'),
    _Destination(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  void _openAddHabit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddEditHabitScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          StatsScreen(),
          SettingsScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddHabit,
        tooltip: 'Add habit',
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _NavBar(
        destinations: _destinations,
        index: _index,
        onSelected: (i) => setState(() => _index = i),
        background: theme.colorScheme.surface,
        border: theme.dividerColor,
      ),
    );
  }
}

class _Destination {
  const _Destination({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Hand-rolled rather than a [BottomNavigationBar] because the docked FAB
/// has to sit in a gap in the middle of the row; a stock bar would put its
/// items underneath the button.
class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.destinations,
    required this.index,
    required this.onSelected,
    required this.background,
    required this.border,
  });

  final List<_Destination> destinations;
  final int index;
  final ValueChanged<int> onSelected;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++) ...[
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == index,
                    onTap: () => onSelected(i),
                  ),
                ),
                // Gap for the docked FAB, between the 2nd and 3rd item.
                if (i == 1) const SizedBox(width: 72),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap});

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? destination.activeIcon : destination.icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
