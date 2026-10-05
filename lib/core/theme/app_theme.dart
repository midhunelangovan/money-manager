import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme([AppAccentColor accent = AppAccentColor.slateBlue]) {
    final primaryColor = accent.primary;
    final primaryLightColor = accent.primaryLight;
    final primaryContainerColor = accent.container;

    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryContainerColor,
      onPrimaryContainer: primaryColor,
      secondary: primaryLightColor,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      error: AppColors.expense,
      onError: Colors.white,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorderSubtle,
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary, letterSpacing: -0.8),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.2),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary, letterSpacing: -0.1),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.1),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
      bodyMedium: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, color: AppColors.lightTextSecondary),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.lightTextTertiary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary, letterSpacing: 0.3),
      labelSmall: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.lightTextTertiary, letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      fontFamily: 'Inter',
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.lightTextSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurfaceCard,
        modalBackgroundColor: AppColors.lightSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.lightSurfaceCard,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primaryColor,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        headerHelpStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
        dayStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.lightTextMuted;
          return AppColors.lightTextPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(primaryColor),
        todayBorder: BorderSide(color: primaryColor, width: 1.5),
        yearStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.lightTextMuted;
          return AppColors.lightTextPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        dividerColor: AppColors.lightBorder,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.lightSurfaceCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        suffixStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: AppColors.lightTextTertiary,
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceElevated,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        secondaryLabelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.lightBorder)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 2,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return const IconThemeData(color: AppColors.lightTextSecondary, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData darkTheme([AppAccentColor accent = AppAccentColor.slateBlue]) {
    final primaryColor = accent.primary;
    final primaryLightColor = accent.primaryLight;

    final colorScheme = ColorScheme.dark(
      primary: primaryLightColor,
      onPrimary: Colors.white,
      primaryContainer: primaryColor,
      onPrimaryContainer: Colors.white,
      secondary: primaryLightColor,
      onSecondary: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      error: AppColors.expense,
      onError: Colors.white,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorderSubtle,
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.darkTextPrimary, letterSpacing: -0.8),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.2),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary, letterSpacing: -0.1),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary, letterSpacing: -0.1),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, color: AppColors.darkTextSecondary),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.darkTextTertiary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary, letterSpacing: 0.3),
      labelSmall: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.darkTextTertiary, letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      fontFamily: 'Inter',
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.darkTextSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceCard,
        modalBackgroundColor: AppColors.darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primaryLightColor,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        headerHelpStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
        dayStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.darkTextMuted;
          return AppColors.darkTextPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLightColor;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(primaryLightColor),
        todayBorder: BorderSide(color: primaryLightColor, width: 1.5),
        yearStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.darkTextMuted;
          return AppColors.darkTextPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLightColor;
          return Colors.transparent;
        }),
        dividerColor: AppColors.darkBorder,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.darkSurfaceCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLightColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLightColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryLightColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryLightColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        suffixStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: AppColors.darkTextTertiary,
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        selectedColor: primaryLightColor.withValues(alpha: 0.25),
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        secondaryLabelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: primaryLightColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.darkBorder)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 2,
        indicatorColor: primaryLightColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryLightColor,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryLightColor, size: 24);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
