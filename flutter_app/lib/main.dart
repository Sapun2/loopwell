import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding_screen.dart';
import 'services/habit_store.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HabitStore.create();
  runApp(LoopwellApp(store: store));
}

class LoopwellApp extends StatelessWidget {
  const LoopwellApp({super.key, required this.store});

  final HabitStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HabitStore>.value(
      value: store,
      child: Consumer<HabitStore>(
        builder: (context, store, child) {
          return MaterialApp(
            title: 'Loopwell',
            debugShowCheckedModeBanner: false,
            themeMode: store.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: child,
          );
        },
        // Built once and handed to every rebuild: the gate has to be the
        // route's own widget, not a value computed out here, so that
        // flipping the onboarding flag actually swaps what is on screen.
        // MaterialApp only reads `home` when it builds the initial route,
        // so a gate evaluated in this builder would be ignored from then on.
        child: const _RootGate(),
      ),
    );
  }
}

/// Decides between Onboarding (FR1) and the main app shell, and rebuilds
/// itself whenever the store's onboarding flag changes. Sign Out flips that
/// flag and pops back to this route, which is what returns the user to the
/// welcome screens.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<HabitStore, bool>((s) => s.onboardingComplete);
    return onboarded ? const AppShell() : const OnboardingScreen();
  }
}
