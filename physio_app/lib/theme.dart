import 'package:flutter/material.dart';

/// Warm, calm medical-wellness palette — slate grays, muted blues, and
/// a soft teal accent. Deliberately avoids high-contrast, "gym app" reds
/// and blacks so the app feels safe and low-stress to use daily.
class AppColors {
  AppColors._();

  static const Color slate900 = Color(0xFF273042);
  static const Color slate700 = Color(0xFF4A5568);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate100 = Color(0xFFF1F5F9);

  static const Color mutedBlue = Color(0xFF5B7FA6);
  static const Color calmTeal = Color(0xFF4FA8A0);
  static const Color calmTealLight = Color(0xFFE3F2F0);

  static const Color background = Color(0xFFFAFBFC);
  static const Color cardSurface = Colors.white;
}

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.calmTeal,
      secondary: AppColors.mutedBlue,
      surface: AppColors.cardSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.slate900,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.slate900,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.slate900,
      displayColor: AppColors.slate900,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9EDF2)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.calmTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.calmTeal
            : AppColors.slate400,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.calmTealLight
            : AppColors.slate100,
      ),
    ),
  );
}
