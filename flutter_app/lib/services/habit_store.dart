import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// Single source of truth for app data: the habit list, theme mode, and
/// onboarding status. A plain ChangeNotifier is enough here — the data set
/// is small and there is no server state to reconcile, so a heavier state
/// management package would be complexity without benefit (see NFR:
/// Privacy — no account, everything lives on this device).
///
/// Convention: screens must only mutate habits through this store's
/// methods (addHabit / updateHabit / toggleCompletion / deleteHabit), never
/// by calling mutating methods on a Habit object pulled from [habits]
/// directly — otherwise the change will not be persisted or notified.
class HabitStore extends ChangeNotifier {
  HabitStore._(this._prefs);

  static const _habitsKey = 'loopwell.habits.v1';
  static const _themeModeKey = 'loopwell.theme_mode.v1';
  static const _onboardingKey = 'loopwell.onboarding_complete.v1';
  static const _notificationsKey = 'loopwell.notifications_enabled.v1';
  static const _userNameKey = 'loopwell.user_name.v1';

  final SharedPreferences _prefs;

  List<Habit> _habits = [];
  ThemeMode _themeMode = ThemeMode.system;
  bool _onboardingComplete = false;
  bool _notificationsEnabled = false;
  String _userName = 'Alex Kim';

  List<Habit> get habits => List.unmodifiable(_habits);
  ThemeMode get themeMode => _themeMode;
  bool get onboardingComplete => _onboardingComplete;
  bool get notificationsEnabled => _notificationsEnabled;
  String get userName => _userName;

  /// Initials for the Settings profile avatar ("Alex Kim" -> "AK").
  String get userInitials {
    final parts = _userName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  /// "Member since" date for the profile row: the oldest habit's createdAt,
  /// falling back to today for a brand new install with no habits.
  DateTime get memberSince {
    if (_habits.isEmpty) return DateTime.now();
    return _habits
        .map((h) => h.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Habits completed today, across every habit scheduled for today.
  int doneOn(DateTime date) =>
      scheduledFor(date).where((h) => h.isCompletedOn(date)).length;

  static Future<HabitStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = HabitStore._(prefs);
    final seeded = store._load();
    // Write the seed straight back out. Without this the sample habits are
    // regenerated relative to "now" on every cold start, so createdAt and
    // the whole completion history silently shift a day each launch and the
    // streaks stop making sense.
    if (seeded) await store._persistHabits();
    return store;
  }

  /// Returns true if the habit list was seeded (and so needs persisting).
  bool _load() {
    _onboardingComplete = _prefs.getBool(_onboardingKey) ?? false;
    _notificationsEnabled = _prefs.getBool(_notificationsKey) ?? false;

    final modeIndex = _prefs.getInt(_themeModeKey);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    _userName = _prefs.getString(_userNameKey) ?? 'Alex Kim';

    final raw = _prefs.getString(_habitsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _habits = decoded
            .map((e) => Habit.fromJson(e as Map<String, dynamic>))
            .toList();
        return false;
      } catch (_) {
        // Corrupt local data should never crash the app on launch — start
        // fresh instead. This only ever affects this one device, there is
        // no server copy at risk.
        _habits = [];
        return true;
      }
    }
    // First ever launch: seed a few sample habits so Home is not an empty,
    // unscreenshottable void. Real usage starts from FR3 (Create habit)
    // same as any other habit.
    _habits = _seedHabits();
    return true;
  }

  Future<void> _persistHabits() async {
    final encoded = jsonEncode(_habits.map((h) => h.toJson()).toList());
    await _prefs.setString(_habitsKey, encoded);
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();
    await _prefs.setBool(_onboardingKey, true);
  }

  /// Used by Settings > Sign Out. There is no real account system (see
  /// NFR: Privacy), so "signing out" is implemented honestly as returning
  /// to onboarding rather than faking a login screen with nothing behind
  /// it.
  Future<void> resetOnboarding() async {
    _onboardingComplete = false;
    notifyListeners();
    await _prefs.setBool(_onboardingKey, false);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _userName = trimmed;
    notifyListeners();
    await _prefs.setString(_userNameKey, trimmed);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    notifyListeners();
    await _persistHabits();
  }

  Future<void> updateHabit(Habit updated) async {
    final index = _habits.indexWhere((h) => h.id == updated.id);
    if (index == -1) return;
    _habits[index] = updated;
    notifyListeners();
    await _persistHabits();
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
    await _persistHabits();
  }

  Future<void> toggleCompletion(String id, DateTime date) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    _habits[index].toggleCompletion(date);
    notifyListeners();
    await _persistHabits();
  }

  Habit? byId(String id) {
    for (final h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// Habits scheduled for [date].
  List<Habit> scheduledFor(DateTime date) =>
      _habits.where((h) => h.isScheduledOn(date)).toList();

  /// Pretty-printed JSON of every habit, for Settings > Data & Export.
  String exportJson() {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': _habits.map((h) => h.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  static List<Habit> _seedHabits() {
    final now = DateTime.now();

    Habit seed(
      String id,
      String name,
      String icon,
      int color,
      int daysAgoCreated,
      List<int> completedOffsets,
    ) {
      final habit = Habit(
        id: id,
        name: name,
        iconKey: icon,
        colorIndex: color,
        createdAt: now.subtract(Duration(days: daysAgoCreated)),
      );
      for (final offset in completedOffsets) {
        habit.toggleCompletion(now.subtract(Duration(days: offset)));
      }
      return habit;
    }

    // Mirrors the Figma Home frame (design/screenshots/hifi_2_home.png):
    // five habits, three of them already done today, with enough history
    // behind them for the Detail heat map to be worth looking at.
    List<int> run(int from, int to, {Set<int> skip = const {}}) => [
          for (var d = from; d <= to; d++)
            if (!skip.contains(d)) d,
        ];

    return [
      seed('seed-1', 'Drink Water', 'water', 1, 40, run(0, 33, skip: {12, 19, 27})),
      seed('seed-2', 'Read 20 Pages', 'book', 0, 40, run(0, 30, skip: {5, 6, 13, 20, 21, 28})),
      seed('seed-3', 'Strength Training', 'fitness', 3, 40, run(0, 24, skip: {3, 4, 10, 17, 18, 24})),
      seed('seed-4', 'Morning Run', 'run', 2, 40, run(1, 26, skip: {2, 9, 15, 16, 23})),
      seed('seed-5', 'Sleep by 11pm', 'sleep', 4, 40, run(1, 29, skip: {7, 8, 14, 22})),
    ];
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
