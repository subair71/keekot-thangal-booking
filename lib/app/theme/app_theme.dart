import 'package:flutter/material.dart';

abstract final class AppColors {
  static const emerald = Color(0xFF13382D),
      secondary = Color(0xFF386653),
      ivory = Color(0xFFFBF9F5);
  static const white = Color(0xFFFFFFFF),
      cream = Color(0xFFF3EFE6),
      outline = Color(0xFFDCD6C7);
  static const gold = Color(0xFFB89354),
      mint = Color(0xFFEDF4EF),
      mintStrong = Color(0xFFE9DCC0);
  static const ink = Color(0xFF202722),
      muted = Color(0xFF5C675E),
      rose = Color(0xFFFFF1F2),
      error = Color(0xFFA3382D);
  static const forest = Color(0xFF0E2921),
      brass = Color(0xFFC8A462),
      available = Color(0xFF226B4A),
      limited = Color(0xFFB87A2B),
      limitedText = Color(0xFF80521A),
      goldText = Color(0xFF795B2C);
  static const disabled = Color(0xFFEAE5DA);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta Sans',
    fontFamilyFallback: const ['Noto Sans Malayalam'],
    scaffoldBackgroundColor: AppColors.ivory,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      primary: AppColors.emerald,
      secondary: AppColors.secondary,
      surface: AppColors.ivory,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      onPrimary: AppColors.ivory,
      primaryContainer: AppColors.cream,
      onPrimaryContainer: AppColors.emerald,
      secondaryContainer: AppColors.cream,
      onSecondaryContainer: AppColors.emerald,
      outline: AppColors.secondary,
      outlineVariant: AppColors.outline,
      error: AppColors.error,
    ),
  );
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.emerald)
        .copyWith(
          displayLarge: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 48,
            height: 1.22,
            fontWeight: FontWeight.w500,
            color: AppColors.emerald,
          ),
          headlineLarge: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 32,
            height: 1.28,
            fontWeight: FontWeight.w500,
            color: AppColors.emerald,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: AppColors.emerald,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            height: 1.6,
            color: AppColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            height: 1.6,
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
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: shape,
        side: const BorderSide(color: AppColors.outline),
        foregroundColor: AppColors.emerald,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.all(16),
      floatingLabelStyle: const TextStyle(
        color: AppColors.emerald,
        fontWeight: FontWeight.w600,
      ),
      helperMaxLines: 3,
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.mintStrong,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.emerald
              : AppColors.muted,
        ),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: AppColors.emerald, size: 21),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 400),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.emerald,
      contentTextStyle: const TextStyle(color: AppColors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.emerald,
      linearTrackColor: AppColors.mint,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.white,
      selectedColor: AppColors.mintStrong,
      side: const BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.ivory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.ivory,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.ivory,
      foregroundColor: AppColors.emerald,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.ivory),
    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(AppColors.cream),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.emerald,
      ),
      dataTextStyle: const TextStyle(color: AppColors.ink, fontSize: 14),
      dividerThickness: 1,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 96,
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.ivory,
      headerBackgroundColor: AppColors.emerald,
      headerForegroundColor: AppColors.ivory,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.ivory,
      elevation: 2,
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(fontSize: 16, color: AppColors.ink),
    ),
    focusColor: AppColors.brass.withValues(alpha: .28),
    dividerColor: AppColors.outline,
  );
}
