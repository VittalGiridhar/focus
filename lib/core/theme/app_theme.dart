import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
}

/// One dark palette with a single electric accent: calm, minimal, futuristic.
abstract final class AppColors {
  static const background = Color(0xFF07090C);
  static const surface = Color(0xFF0D1116);
  static const surfaceRaised = Color(0xFF131920);
  static const surfaceHighest = Color(0xFF1A2129);
  static const outline = Color(0xFF1E2630);
  static const outlineStrong = Color(0xFF2C3744);
  static const accent = Color(0xFF3CF0DC);
  static const accentDim = Color(0xFF0E2B29);
  static const onAccent = Color(0xFF00201D);
  static const violet = Color(0xFF8C7CFF);
  static const text = Color(0xFFE9EEF3);
  static const textMuted = Color(0xFF8A97A6);
  static const danger = Color(0xFFFF5C7A);
}

abstract final class AppText {
  /// Small, spaced, monospace label used for section headers and status lines.
  static TextStyle hud(BuildContext context, {Color? color}) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textMuted,
      );

  /// A soft glow for key numbers such as countdowns.
  static List<Shadow> glow([Color color = AppColors.accent]) => [
        Shadow(color: color.withValues(alpha: 0.55), blurRadius: 18),
      ];
}

/// Uppercase section label, e.g. "LAST 7 DAYS".
class HudLabel extends StatelessWidget {
  const HudLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppText.hud(context, color: color));
}

abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.accentDim,
      onPrimaryContainer: AppColors.accent,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      secondaryContainer: AppColors.accentDim,
      onSecondaryContainer: AppColors.accent,
      tertiary: AppColors.violet,
      error: AppColors.danger,
      onError: Color(0xFF2B000A),
      surface: AppColors.background,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceRaised,
      surfaceContainerHighest: AppColors.surfaceHighest,
      outline: AppColors.outlineStrong,
      outlineVariant: AppColors.outline,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.dark);
    final text = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.8),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.5),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w400, letterSpacing: -0.3),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    const pill = StadiumBorder();
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.outline),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: pill,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: pill,
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.45)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(48, 48),
          shape: pill,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: AppColors.outlineStrong)),
        side: const BorderSide(color: AppColors.outlineStrong),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accentDim,
        showCheckmark: false,
        labelStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        indicatorColor: AppColors.accentDim,
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.onAccent : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.surfaceHighest,
        ),
        trackOutlineColor: WidgetStateProperty.all(AppColors.outlineStrong),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.outlineStrong),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.outlineStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHighest,
        contentTextStyle: TextStyle(color: AppColors.text),
        actionTextColor: AppColors.accent,
        shape: StadiumBorder(side: BorderSide(color: AppColors.outlineStrong)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.outline,
        circularTrackColor: AppColors.outline,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(AppColors.surfaceRaised),
        shape: WidgetStateProperty.all(
          const StadiumBorder(side: BorderSide(color: AppColors.outline)),
        ),
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.textMuted),
      dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accent : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(AppColors.onAccent),
        side: const BorderSide(color: AppColors.outlineStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
