import 'package:flutter/material.dart';

/// Every colour used anywhere in the app lives here. Nothing should be
/// hardcoded as a literal Color(...) inside a screen — pull it from
/// AppColors instead, so the app stays visually consistent with the Figma
/// prototype and with design/design_tokens.md.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF5B4FE8);
  static const primaryDark = Color(0xFF4438C7);
  static const primaryTint = Color(0xFFEFEDFD);
  static const teal = Color(0xFF00C2A8);
  static const tealTint = Color(0xFFD9F5F0);
  static const coral = Color(0xFFFF7A59);
  static const coralTint = Color(0xFFFFE7E0);
  static const amber = Color(0xFFF2A93B);
  static const amberTint = Color(0xFFFCEFD9);
  static const lightIndigo = Color(0xFF6C6FE0);
  static const lightIndigoTint = Color(0xFFE8E8FB);
  static const green = Color(0xFF3BB273);
  static const greenTint = Color(0xFFDFF5E7);

  /// Destructive actions. The Figma prototype uses the Coral token for
  /// "Delete Habit" / "Sign Out" rather than a separate red, so Coral is
  /// the error colour here too — see design_tokens.md ("Coral — optional
  /// habit colour, destructive accents").
  static const error = coral;

  static const bgLight = Color(0xFFF6F7FB);
  static const cardLight = Color(0xFFFFFFFF);
  static const textLight = Color(0xFF1F2430);
  static const mutedLight = Color(0xFF8A8FA3);
  static const borderLight = Color(0xFFE7E9F3);

  static const bgDark = Color(0xFF14151F);
  static const cardDark = Color(0xFF1E2030);
  static const textDark = Color(0xFFF2F3F7);
  static const mutedDark = Color(0xFF9AA0B4);
  static const borderDark = Color(0xFF2C2E42);

  /// The six habit colour swatches offered on the Add / Edit Habit screen.
  /// A Habit stores an *index* into this list (see Habit.colorIndex), never
  /// a raw Color — that keeps persistence a plain int and avoids any
  /// dependency on Color's int-conversion API, which has changed across
  /// Flutter versions.
  static const List<Color> habitSwatches = [
    primary,
    teal,
    coral,
    amber,
    lightIndigo,
    green,
  ];

  /// Light background tints, in the same order as [habitSwatches] — used
  /// behind a habit's icon on cards.
  static const List<Color> habitSwatchTints = [
    primaryTint,
    tealTint,
    coralTint,
    amberTint,
    lightIndigoTint,
    greenTint,
  ];

  static Color swatchAt(int index) =>
      habitSwatches[index.clamp(0, habitSwatches.length - 1)];

  static Color tintAt(int index) =>
      habitSwatchTints[index.clamp(0, habitSwatchTints.length - 1)];

  /// Tints are designed for the light theme (they are near-white). On dark
  /// surfaces they blow out, so derive a low-alpha version of the swatch
  /// instead. Every "icon on a tinted circle" in the app goes through here.
  static Color tintFor(BuildContext context, int index) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? swatchAt(index).withValues(alpha: 0.18) : tintAt(index);
  }
}

class AppRadius {
  AppRadius._();
  static const double chip = 12.0;
  static const double card = 16.0;
  static const double pill = 24.0;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double screenMargin = 24.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(
        brightness: Brightness.light,
        background: AppColors.bgLight,
        surface: AppColors.cardLight,
        onSurface: AppColors.textLight,
        muted: AppColors.mutedLight,
        border: AppColors.borderLight,
      );

  static ThemeData dark() => _base(
        brightness: Brightness.dark,
        background: AppColors.bgDark,
        surface: AppColors.cardDark,
        onSurface: AppColors.textDark,
        muted: AppColors.mutedDark,
        border: AppColors.borderDark,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color muted,
    required Color border,
  }) {
    // Start from a seeded Material 3 scheme (fills in every tonal surface
    // role correctly for the current Flutter version) then overwrite the
    // handful of roles that must match the Loopwell brand hexes exactly.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.teal,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      // Material 3 routes a lot of "muted caption" work through
      // onSurfaceVariant; pin it to the Muted token so secondary text is
      // the same grey everywhere instead of a tonal approximation.
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      error: AppColors.error,
      onError: Colors.white,
    );

    final textTheme = TextTheme(
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface, height: 1.25),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: onSurface),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: muted),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      // Uppercase section labels on Add/Edit and Settings.
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: muted,
        letterSpacing: 0.8,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: muted,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          // WCAG 2.1 AA / NFR: no tappable control below 44pt.
          minimumSize: const Size(64, 44),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : border,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : border,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: TextStyle(color: surface, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide(color: border),
        selectedColor: AppColors.primary,
        showCheckmark: false,
        labelStyle: textTheme.bodyMedium,
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}
