import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme([AppAccentColor accent = AppAccentColor.slateBlue, bool isMinimalMode = false]) {
    final primaryColor = isMinimalMode ? AppColors.minimalLightPrimary : accent.primary;
    final primaryLightColor = isMinimalMode ? AppColors.minimalLightSecondary : accent.primaryLight;
    final primaryContainerColor = isMinimalMode ? AppColors.minimalLightPrimaryContainer : accent.container;

    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryContainerColor,
      onPrimaryContainer: primaryColor,
      secondary: primaryLightColor,
      onSecondary: Colors.white,
      surface: isMinimalMode ? AppColors.minimalLightSurface : AppColors.lightSurface,
      onSurface: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary,
      surfaceContainerHighest: isMinimalMode ? AppColors.minimalLightSurfaceElevated : AppColors.lightSurfaceElevated,
      error: isMinimalMode ? AppColors.minimalLightTextSecondary : AppColors.expense,
      onError: Colors.white,
      outline: isMinimalMode ? AppColors.minimalLightBorder : AppColors.lightBorder,
      outlineVariant: isMinimalMode ? AppColors.minimalLightBorderSubtle : AppColors.lightBorderSubtle,
    );

    final textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary, letterSpacing: -0.8),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary, letterSpacing: -0.2),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary, letterSpacing: -0.1),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary, letterSpacing: -0.1),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary),
      bodyMedium: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, color: isMinimalMode ? AppColors.minimalLightTextSecondary : AppColors.lightTextSecondary),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: isMinimalMode ? AppColors.minimalLightTextTertiary : AppColors.lightTextTertiary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalLightTextSecondary : AppColors.lightTextSecondary, letterSpacing: 0.3),
      labelSmall: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalLightTextTertiary : AppColors.lightTextTertiary, letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isMinimalMode ? AppColors.minimalLightBackground : AppColors.lightBackground,
      canvasColor: isMinimalMode ? AppColors.minimalLightBackground : AppColors.lightBackground,
      fontFamily: 'Inter',
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isMinimalMode ? AppColors.minimalLightSurface : AppColors.lightSurface,
        foregroundColor: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: isMinimalMode ? AppColors.minimalLightSurfaceCard : AppColors.lightSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isMinimalMode ? AppColors.minimalLightBorder : AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isMinimalMode ? AppColors.minimalLightSurfaceCard : AppColors.lightSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isMinimalMode ? AppColors.minimalLightTextPrimary : AppColors.lightTextPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: isMinimalMode ? AppColors.minimalLightTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isMinimalMode ? AppColors.minimalLightSurfaceCard : AppColors.lightSurfaceCard,
        modalBackgroundColor: isMinimalMode ? AppColors.minimalLightSurfaceCard : AppColors.lightSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isMinimalMode ? AppColors.minimalLightPrimary : AppColors.floatingAction,
        foregroundColor: isMinimalMode ? Colors.white : const Color(0xFF1B1E24),
        elevation: 3,
        shape: const CircleBorder(),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.lightSurfaceCard,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.lightSurfaceElevated,
        headerForegroundColor: AppColors.lightTextPrimary,
        headerHeadlineStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
        headerHelpStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
        weekdayStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary),
        dayStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.lightTextDisabled;
          return AppColors.lightTextPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return primaryColor;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        todayBorder: BorderSide(color: primaryColor, width: 1.5),
        yearStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.lightTextDisabled;
          return AppColors.lightTextPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        rangePickerHeaderBackgroundColor: AppColors.lightSurfaceElevated,
        rangePickerHeaderForegroundColor: AppColors.lightTextPrimary,
        rangePickerBackgroundColor: AppColors.lightSurfaceCard,
        rangeSelectionBackgroundColor: primaryColor.withValues(alpha: 0.15),
        rangeSelectionOverlayColor: WidgetStateProperty.all(primaryColor.withValues(alpha: 0.1)),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        dividerColor: AppColors.lightBorder,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.lightSurfaceCard,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor.withValues(alpha: 0.15);
          return AppColors.lightSurfaceElevated;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return AppColors.lightTextPrimary;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor.withValues(alpha: 0.15);
          return AppColors.lightSurfaceElevated;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return AppColors.lightTextSecondary;
        }),
        dayPeriodBorderSide: const BorderSide(color: AppColors.lightBorder),
        dialHandColor: primaryColor,
        dialBackgroundColor: AppColors.lightSurfaceElevated,
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.lightTextPrimary;
        }),
        entryModeIconColor: primaryColor,
        timeSelectorSeparatorColor: WidgetStateColor.resolveWith((_) => AppColors.lightTextPrimary),
        timeSelectorSeparatorTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        helpTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextSecondary,
        ),
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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData darkTheme([AppAccentColor accent = AppAccentColor.slateBlue, bool isMinimalMode = false]) {
    final darkPrimaryColor = isMinimalMode ? AppColors.minimalDarkPrimary : accent.darkPrimary;
    final darkPrimaryLightColor = isMinimalMode ? AppColors.minimalDarkSecondary : accent.primaryLight;
    final darkContainerColor = isMinimalMode ? AppColors.minimalDarkPrimaryContainer : accent.darkContainer;

    final colorScheme = ColorScheme.dark(
      primary: darkPrimaryColor,
      onPrimary: isMinimalMode ? AppColors.minimalDarkBackground : AppColors.darkBackground,
      primaryContainer: darkContainerColor,
      onPrimaryContainer: isMinimalMode ? AppColors.minimalDarkTextPrimary : darkPrimaryColor,
      secondary: darkPrimaryLightColor,
      onSecondary: isMinimalMode ? AppColors.minimalDarkBackground : AppColors.darkBackground,
      surface: isMinimalMode ? AppColors.minimalDarkSurface : AppColors.darkSurface,
      onSurface: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary,
      surfaceContainerHighest: isMinimalMode ? AppColors.minimalDarkSurfaceElevated : AppColors.darkSurfaceElevated,
      error: isMinimalMode ? AppColors.minimalDarkTextSecondary : AppColors.expense,
      onError: isMinimalMode ? AppColors.minimalDarkBackground : Colors.white,
      outline: isMinimalMode ? AppColors.minimalDarkBorder : AppColors.darkBorder,
      outlineVariant: isMinimalMode ? AppColors.minimalDarkBorderSubtle : AppColors.darkBorderSubtle,
    );

    final textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary, letterSpacing: -0.8),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary, letterSpacing: -0.2),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary, letterSpacing: -0.1),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary, letterSpacing: -0.1),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary),
      bodyMedium: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, color: isMinimalMode ? AppColors.minimalDarkTextSecondary : AppColors.darkTextSecondary),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: isMinimalMode ? AppColors.minimalDarkTextTertiary : AppColors.darkTextTertiary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalDarkTextSecondary : AppColors.darkTextSecondary, letterSpacing: 0.3),
      labelSmall: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isMinimalMode ? AppColors.minimalDarkTextTertiary : AppColors.darkTextTertiary, letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isMinimalMode ? AppColors.minimalDarkBackground : AppColors.darkBackground,
      canvasColor: isMinimalMode ? AppColors.minimalDarkBackground : AppColors.darkBackground,
      fontFamily: 'Inter',
      iconTheme: IconThemeData(color: isMinimalMode ? AppColors.minimalDarkIconPrimary : AppColors.darkIconPrimary, size: 24),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isMinimalMode ? AppColors.minimalDarkSurface : AppColors.darkSurface,
        foregroundColor: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: isMinimalMode ? AppColors.minimalDarkSurfaceCard : AppColors.darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isMinimalMode ? AppColors.minimalDarkBorder : AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isMinimalMode ? AppColors.minimalDarkSurfaceCard : AppColors.darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isMinimalMode ? AppColors.minimalDarkTextPrimary : AppColors.darkTextPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: isMinimalMode ? AppColors.minimalDarkTextSecondary : AppColors.darkTextSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isMinimalMode ? AppColors.minimalDarkSurfaceCard : AppColors.darkSurfaceCard,
        modalBackgroundColor: isMinimalMode ? AppColors.minimalDarkSurfaceCard : AppColors.darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isMinimalMode ? AppColors.minimalDarkPrimary : AppColors.floatingAction,
        foregroundColor: isMinimalMode ? AppColors.minimalDarkBackground : const Color(0xFF1B1E24),
        elevation: 3,
        shape: const CircleBorder(),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.darkSurfaceElevated,
        headerForegroundColor: AppColors.darkTextPrimary,
        headerHeadlineStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkTextPrimary),
        headerHelpStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
        weekdayStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkTextSecondary),
        dayStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.darkTextDisabled;
          return AppColors.darkTextPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimaryColor;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return darkPrimaryColor;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimaryColor;
          return Colors.transparent;
        }),
        todayBorder: BorderSide(color: darkPrimaryColor, width: 1.5),
        yearStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.darkTextDisabled;
          return AppColors.darkTextPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimaryColor;
          return Colors.transparent;
        }),
        rangePickerHeaderBackgroundColor: AppColors.darkSurfaceElevated,
        rangePickerHeaderForegroundColor: AppColors.darkTextPrimary,
        rangePickerBackgroundColor: AppColors.darkSurfaceCard,
        rangeSelectionBackgroundColor: darkPrimaryColor.withValues(alpha: 0.25),
        rangeSelectionOverlayColor: WidgetStateProperty.all(darkPrimaryColor.withValues(alpha: 0.1)),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        dividerColor: AppColors.darkBorder,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.darkSurfaceCard,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimaryColor.withValues(alpha: 0.25);
          return AppColors.darkSurfaceElevated;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimaryColor;
          return AppColors.darkTextPrimary;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimaryColor.withValues(alpha: 0.25);
          return AppColors.darkSurfaceElevated;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimaryColor;
          return AppColors.darkTextSecondary;
        }),
        dayPeriodBorderSide: const BorderSide(color: AppColors.darkBorder),
        dialHandColor: darkPrimaryColor,
        dialBackgroundColor: AppColors.darkSurfaceElevated,
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.darkTextPrimary;
        }),
        entryModeIconColor: darkPrimaryColor,
        timeSelectorSeparatorColor: WidgetStateColor.resolveWith((_) => AppColors.darkTextPrimary),
        timeSelectorSeparatorTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        helpTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: AppColors.darkBackground,
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
          foregroundColor: darkPrimaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputSurface,
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
          borderSide: BorderSide(color: darkPrimaryColor, width: 1.5),
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
          color: darkPrimaryColor,
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
        selectedColor: darkPrimaryColor.withValues(alpha: 0.25),
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        secondaryLabelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: darkPrimaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.darkBorder)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 2,
        indicatorColor: darkPrimaryColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkPrimaryColor,
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
            return IconThemeData(color: darkPrimaryColor, size: 24);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary, size: 24);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
