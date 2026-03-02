import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.scaffoldBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryGreen,
      secondary: AppColors.primaryRed,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.grey900,
      onBackground: AppColors.grey900,
      onError: AppColors.white,
    ),
    fontFamily: 'Cairo',

    // AppBar Theme - Green theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.primaryGreen,
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
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primaryGreen,
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
      color: AppColors.white,
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
        backgroundColor: AppColors.primaryGreen,
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
        foregroundColor: AppColors.primaryGreen,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
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
        foregroundColor: AppColors.primaryGreen,
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
      fillColor: AppColors.grey100,
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
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
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
        color: AppColors.grey700,
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.error,
      ),
      prefixIconColor: AppColors.grey600,
      suffixIconColor: AppColors.grey600,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey100,
      selectedColor: AppColors.greenSurface,
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.grey700,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.primaryGreen,
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
      backgroundColor: AppColors.white,
      elevation: AppDimens.elevationL,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        color: AppColors.grey700,
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
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
      labelColor: AppColors.primaryGreen,
      unselectedLabelColor: AppColors.grey500,
      indicatorColor: AppColors.primaryGreen,
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
        color: AppColors.grey900,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontHeadline,
        fontWeight: FontWeight.w700,
        color: AppColors.grey900,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontTitle,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXXL,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontL,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontL,
        fontWeight: FontWeight.w400,
        color: AppColors.grey800,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        fontWeight: FontWeight.w400,
        color: AppColors.grey700,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w400,
        color: AppColors.grey600,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontM,
        fontWeight: FontWeight.w600,
        color: AppColors.grey900,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        fontWeight: FontWeight.w500,
        color: AppColors.grey700,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontXS,
        fontWeight: FontWeight.w500,
        color: AppColors.grey600,
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.greenLight,
    scaffoldBackgroundColor: AppColors.grey900,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.greenLight,
      secondary: AppColors.redLight,
      surface: AppColors.grey800,
      background: AppColors.grey900,
      error: AppColors.redLight,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
      onBackground: AppColors.white,
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
      selectedItemColor: AppColors.greenLight,
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
        backgroundColor: AppColors.greenLight,
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
        foregroundColor: AppColors.greenLight,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        side: const BorderSide(color: AppColors.greenLight, width: 1.5),
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
        foregroundColor: AppColors.greenLight,
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
        borderSide: const BorderSide(color: AppColors.greenLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.redLight, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        borderSide: const BorderSide(color: AppColors.redLight, width: 2),
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
        color: AppColors.redLight,
      ),
      prefixIconColor: AppColors.grey400,
      suffixIconColor: AppColors.grey400,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.greenLight,
      foregroundColor: AppColors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey700,
      selectedColor: AppColors.grey600,
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.grey300,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: AppDimens.fontS,
        color: AppColors.greenLight,
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
            ? AppColors.greenLight
            : AppColors.grey500,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.greenLight.withValues(alpha: 0.4)
            : AppColors.grey700,
      ),
    ),
  );
}
