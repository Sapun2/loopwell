# Loopwell — Flutter application

The application source. See the [repository README](../README.md) for an
overview and [`RUN_GUIDE.md`](../RUN_GUIDE.md) for setup instructions.

```bash
flutter pub get
flutter run
```

## Source layout

```
lib/
├── main.dart                     entry point and the onboarding/shell gate
├── models/
│   ├── habit.dart                the Habit model and its derived statistics
│   └── habit_icons.dart          the icon set a habit can be given
├── services/
│   └── habit_store.dart          application state and local persistence
├── screens/
│   ├── onboarding_screen.dart
│   ├── home_screen.dart          the daily dashboard
│   ├── add_edit_habit_screen.dart
│   ├── habit_detail_screen.dart  streak, completion rate and heat map
│   ├── stats_screen.dart         aggregate statistics
│   ├── settings_screen.dart
│   └── profile_screen.dart
├── theme/
│   └── app_theme.dart            the entire design system
└── widgets/
    ├── app_shell.dart            bottom navigation and docked action button
    ├── habit_card.dart
    ├── streak_heatmap.dart
    ├── progress_ring.dart
    ├── settings_tile.dart
    └── section_label.dart
```

## Design notes

**State.** A single `HabitStore` (`ChangeNotifier`, exposed with `provider`).
The data set is small and there is no server state to reconcile, so a larger
state management package would add indirection without benefit. Screens mutate
habits only through the store's methods; mutating a `Habit` taken from
`store.habits` directly is neither persisted nor notified.

**Persistence.** `shared_preferences`, with the habit list JSON-encoded under a
single versioned key. There is no backend and no authentication.

**Derived statistics.** `currentStreak`, `bestStreak` and the completion rates
are computed from the completion history on read rather than stored. Persisting
them would let them fall out of step with the underlying data the moment a day
were un-ticked.

**Theming.** `theme/app_theme.dart` is the only place colours, radii, spacing
and type are declared, in both light and dark variants. Screens reference
`AppColors`, `AppRadius` and `AppSpacing` rather than literal values.

**Accessibility.** Every tappable control clears a 44x44 hit area even where
the painted control is smaller, and the completion circle publishes its own
semantics node so it is not merged into its card.

## Tests

```bash
flutter analyze   # expected: No issues found!
flutter test      # 15 unit tests over the derived statistics
```

`test/habit_test.dart` covers streak calculation, the completion-rate
denominator, the frequency labels, JSON round-tripping and `copyWith`
semantics — the logic where an error is invisible in a screenshot but obvious
to a user.
