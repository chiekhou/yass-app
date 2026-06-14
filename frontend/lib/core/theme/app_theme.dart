import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  // Light Theme — fond sombre bleu nuit
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.scaffoldBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryBlue,
      secondary: AppColors.accentGreen,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.black,
      onSurface: AppColors.textPrimary,
      onError: AppColors.white,
    ),
    fontFamily: 'Cairo',

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.scaffoldBackground,
      foregroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      iconTheme: IconThemeData(
        color: AppColors.white,
        size: AppDimens.iconM,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: AppDimens.elevationS,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      margin: const EdgeInsets.all(AppDimens.paddingS),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF1A4DCC),
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppDimens.fontL,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppDimens.fontL,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppDimens.fontM,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        color: AppColors.textHint,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        color: AppColors.textSecondary,
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.error,
      ),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentGreen,
      foregroundColor: AppColors.black,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primaryBlue,
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.textSecondary,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.white,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppDimens.elevationL,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        color: AppColors.textSecondary,
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppDimens.elevationL,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXL),
        ),
      ),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.grey900,
      contentTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        color: AppColors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
    ),

    // Tab Bar Theme
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.primaryBlue,
      unselectedLabelColor: AppColors.grey500,
      indicatorColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.grey200,
      thickness: 1,
      space: 1,
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontDisplay,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontHeadline,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontTitle,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXXL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontL,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXS,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryBlueLight,
    scaffoldBackgroundColor: AppColors.grey900,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryBlueLight,
      secondary: AppColors.accentGreen,
      surface: AppColors.grey800,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.black,
      onSurface: AppColors.white,
      onError: AppColors.white,
    ),
    fontFamily: 'Cairo',

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.grey800,
      foregroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      iconTheme: IconThemeData(
        color: AppColors.white,
        size: AppDimens.iconM,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.grey800,
      selectedItemColor: AppColors.primaryBlueLight,
      unselectedItemColor: AppColors.grey500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: AppDimens.elevationS,
      color: AppColors.grey800,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      margin: const EdgeInsets.all(AppDimens.paddingS),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryBlueLight,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppDimens.fontL,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlueLight,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        side: const BorderSide(color: AppColors.primaryBlueLight, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppDimens.fontL,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBlueLight,
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppDimens.fontM,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey700,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide:
            const BorderSide(color: AppColors.primaryBlueLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        color: AppColors.grey500,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        color: AppColors.grey400,
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.error,
      ),
      prefixIconColor: AppColors.grey400,
      suffixIconColor: AppColors.grey400,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentGreen,
      foregroundColor: AppColors.black,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey700,
      selectedColor: AppColors.primaryBlueDark,
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.grey300,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.primaryBlueLight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.grey800,
      elevation: AppDimens.elevationL,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        color: AppColors.grey300,
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.grey800,
      elevation: AppDimens.elevationL,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXL),
        ),
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.grey700,
      thickness: 1,
    ),

    // List Tile Theme
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.grey400,
      textColor: AppColors.white,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accentGreen
            : AppColors.grey500,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accentGreen.withValues(alpha: 0.4)
            : AppColors.grey700,
      ),
    ),
  );
}
