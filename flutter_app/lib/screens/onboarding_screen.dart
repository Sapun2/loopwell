import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/habit_store.dart';
import '../theme/app_theme.dart';

/// Three-slide introduction carousel. Skip is offered on the first two
/// slides; every path ends on Get Started, which marks onboarding complete
/// and hands control back to the root gate in `main.dart`.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.all_inclusive_rounded,
      title: 'Loopwell',
      tagline: 'Small steps, every day.',
      body: 'Track daily habits with one tap, and build momentum that lasts.',
    ),
    _SlideData(
      icon: Icons.local_fire_department_rounded,
      title: 'Stay Consistent',
      tagline: "Build streaks you're proud of.",
      body:
          'Visual streak counters and gentle reminders keep you on track — guilt-free.',
    ),
    _SlideData(
      icon: Icons.insights_rounded,
      title: 'Track Your Progress',
      tagline: 'See it all at a glance.',
      body:
          "A simple daily dashboard shows exactly how you're doing, today and over time.",
    ),
  ];

  void _finish() => context.read<HabitStore>().completeOnboarding();

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Height is reserved on every slide so the content does not
            // shift when Skip disappears on the last one.
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: isLast
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white),
                          child: const Text('Skip'),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(data: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Earlier slides advance with the circular arrow; the last one
            // commits with a full-width button.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                height: 56,
                child: isLast
                    ? ElevatedButton(
                        onPressed: _finish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('Get Started'),
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _next,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.tagline,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String tagline;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Scrollable so a short viewport does not overflow; centred otherwise.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Shrink the logo mark on short viewports so the copy still fits.
        final markSize = constraints.maxHeight < 420 ? 96.0 : 160.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: markSize,
                  height: markSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.icon,
                    size: markSize * 0.42,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  data.tagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
