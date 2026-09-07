import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The small uppercase group label used above each form section on
/// Add / Edit Habit ("HABIT NAME", "ICON", ...) and above each Settings
/// group ("PREFERENCES", "SUPPORT").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
