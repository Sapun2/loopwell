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
        // MaterialApp only reads `home` when building the initial route, so
        // the gate must be the route's own widget rather than a value
        // computed here; otherwise later flag changes never reach the screen.
        child: const _RootGate(),
      ),
    );
  }
}

/// Chooses between onboarding and the main shell, rebuilding whenever the
/// onboarding flag changes. Sign-out flips the flag and pops to this route.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final onboarded =
        context.select<HabitStore, bool>((s) => s.onboardingComplete);
    return onboarded ? const AppShell() : const OnboardingScreen();
  }
}
