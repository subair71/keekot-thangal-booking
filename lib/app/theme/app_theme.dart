import 'package:flutter/material.dart';

abstract final class AppColors {
  static const emerald = Color(0xFF064E3B),
      secondary = Color(0xFF047857),
      ivory = Color(0xFFFDFBF7);
  static const white = Color(0xFFFFFFFF),
      cream = Color(0xFFF9F6F0),
      outline = Color(0xFFE7E2D9);
  static const gold = Color(0xFFD97706),
      mint = Color(0xFFECFDF5),
      mintStrong = Color(0xFFA7F3D0);
  static const ink = Color(0xFF182D26),
      muted = Color(0xFF59665F),
      rose = Color(0xFFFFF1F2),
      error = Color(0xFF9F1239);
  static const disabled = Color(0xFFF1F5F9);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta Sans',
    scaffoldBackgroundColor: AppColors.ivory,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      primary: AppColors.emerald,
      secondary: AppColors.secondary,
      surface: AppColors.ivory,
      error: AppColors.error,
    ),
  );
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.emerald)
        .copyWith(
          displayLarge: const TextStyle(
            fontFamily: 'Newsreader',
            fontSize: 54,
            height: 1.08,
            fontWeight: FontWeight.w500,
            color: AppColors.emerald,
          ),
          headlineLarge: const TextStyle(
            fontFamily: 'Newsreader',
            fontSize: 36,
            height: 1.18,
            fontWeight: FontWeight.w500,
            color: AppColors.emerald,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Newsreader',
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: AppColors.emerald,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 19,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            height: 1.65,
            color: AppColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            height: 1.5,
            color: AppColors.muted,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: shape,
        backgroundColor: AppColors.emerald,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: shape,
        side: const BorderSide(color: AppColors.outline),
        foregroundColor: AppColors.emerald,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.ivory,
      indicatorColor: AppColors.mintStrong,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
      ),
    ),
    dividerColor: AppColors.outline,
  );
}
