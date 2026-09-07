import 'package:flutter/material.dart';

/// Fixed set of icons offered on the Add / Edit Habit screen. A Habit
/// stores the String key (not an IconData) so the icon choice can be
/// persisted safely as JSON.
class HabitIcons {
  HabitIcons._();

  static const Map<String, IconData> all = {
    'star': Icons.star_rounded,
    'book': Icons.menu_book_rounded,
    'water': Icons.water_drop_rounded,
    'fitness': Icons.fitness_center_rounded,
    'meditate': Icons.self_improvement_rounded,
    'sleep': Icons.bedtime_rounded,
    'food': Icons.restaurant_rounded,
    'run': Icons.directions_run_rounded,
    'art': Icons.brush_rounded,
    'music': Icons.music_note_rounded,
    'code': Icons.code_rounded,
    'heart': Icons.favorite_rounded,
  };

  static const String defaultKey = 'star';

  static IconData resolve(String key) => all[key] ?? all[defaultKey]!;
}
