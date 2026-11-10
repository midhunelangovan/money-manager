import 'package:flutter/material.dart';

class AppColors {
  // Primary / Brand Colors - Extracted from official Kals Money Manager Icon
  // Dominant Owl Silhouette & Body: #03323A (R:3, G:50, B:58)
  static const Color primary = Color(0xFF03323A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFF23818D); // Owl Face Ring Teal (R:35, G:129, B:141)
  static const Color primaryDark = Color(0xFF012127);
  static const Color primaryContainer = Color(0xFFE2EFF1); // Subtle pale tint of #03323A
  static const Color onPrimaryContainer = Color(0xFF03323A);

  // Secondary Brand Accent - Owl Face Teal / Mid Belly
  static const Color secondary = Color(0xFF23818D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE4F3F5);
  static const Color onSecondaryContainer = Color(0xFF02505C);

  // Accent / Floating Button Color - Extracted from Owl Golden Beak: #D5A328 (R:213, G:163, B:40)
  static const Color accentYellow = Color(0xFFD5A328);
  static const Color floatingAction = Color(0xFFD5A328);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Financial Status Colors (Semantic - Preserved for clarity)
  static const Color income = Color(0xFF109B73); // Muted Emerald Green
  static const Color incomeLight = Color(0xFFD7F3E9);
  static const Color incomeDark = Color(0xFF0C7859);

  static const Color expense = Color(0xFFDC3545); // Rose / Crimson
  static const Color expenseLight = Color(0xFFFFE8EA);
  static const Color expenseDark = Color(0xFFB02A37);

  static const Color transfer = Color(0xFF2B70C9); // Royal Blue
  static const Color transferLight = Color(0xFFE1EDFC);
  static const Color transferDark = Color(0xFF1E5296);

  static const Color warning = Color(0xFFE68A00); // Amber
  static const Color warningLight = Color(0xFFFFF1D6);

  static const Color info = Color(0xFF1D8BA8); // Cyan / Sky
  static const Color infoLight = Color(0xFFE2F4F8);

  // Light Palette - Warm matte paper off-white / light-gray
  static const Color lightBackground = Color(0xFFF6F5F2); // Soft warm off-white / light-gray
  static const Color lightSurface = Color(0xFFFAFAF7); // Soft elevated surface
  static const Color lightSurfaceCard = Color(0xFFFCFCFA); // Soft card surface
  static const Color lightSurfaceElevated = Color(0xFFEFEFEA); // Subtle elevated surface
  static const Color lightSurfaceVariant = Color(0xFFEFEFEA);
  static const Color lightInputSurface = Color(0xFFEFEFEA); // Input background
  static const Color lightBorder = Color(0xFFE5E4DE); // Subtle neutral warm border
  static const Color lightOutline = Color(0xFFE5E4DE);
  static const Color lightBorderSubtle = Color(0xFFEDEDE8); // Ultra subtle border
  static const Color lightTextPrimary = Color(0xFF1B1E24); // Crisp dark text
  static const Color lightTextSecondary = Color(0xFF5F6877); // Muted secondary text
  static const Color lightTextTertiary = Color(0xFF808B9D); // Tertiary label text
  static const Color lightTextMuted = Color(0xFF9EA7B5); // Muted placeholder text
  static const Color lightTextDisabled = Color(0xFFB0B7C3); // Disabled text
  static const Color lightIconPrimary = Color(0xFF1B1E24); // Primary icon
  static const Color lightIconSecondary = Color(0xFF5F6877); // Secondary icon
  static const Color lightSelectedBackground = Color(0xFFE2EFF1); // Selected chip/item background
  static const Color lightSelectedText = Color(0xFF03323A); // Selected chip/item text
  static const Color lightDivider = Color(0xFFE5E4DE); // Divider

  // Dark Palette - Deep midnight petrol slate (harmonized with #03323A brand)
  static const Color darkBackground = Color(0xFF071417); // Deep midnight petrol slate
  static const Color darkSurface = Color(0xFF0E1E22); // Dark surface
  static const Color darkSurfaceCard = Color(0xFF14272D); // Dark card surface
  static const Color darkSurfaceElevated = Color(0xFF1B3239); // Elevated dark surface
  static const Color darkSurfaceVariant = Color(0xFF1B3239);
  static const Color darkInputSurface = Color(0xFF112227); // Input field surface
  static const Color darkBorder = Color(0xFF1F3D45); // Subtle dark border
  static const Color darkOutline = Color(0xFF1F3D45);
  static const Color darkBorderSubtle = Color(0xFF162E34); // Ultra subtle dark border
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Very light / crisp off-white (Slate-50)
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // High-contrast light gray (Slate-300)
  static const Color darkTextTertiary = Color(0xFFA6B4C9); // Highly readable medium-light gray (~5.8:1 ratio)
  static const Color darkTextMuted = Color(0xFF8899B0); // Clear, readable muted gray / placeholder (~4.8:1 ratio)
  static const Color darkTextDisabled = Color(0xFF64748B); // Distinguishable disabled text
  static const Color darkIconPrimary = Color(0xFFF8FAFC); // High contrast light icon
  static const Color darkIconSecondary = Color(0xFF94A3B8); // High contrast secondary icon
  static const Color darkPrimary = Color(0xFF38A3B0); // High-contrast luminous teal for dark surfaces
  static const Color darkSelectedBackground = Color(0xFF143037); // Selected item background
  static const Color darkSelectedText = Color(0xFFF8FAFC); // Selected item text
  static const Color darkDivider = Color(0xFF1F3D45); // Dark divider

  // Semantic Helper Getters
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color surfaceCard(bool isDark) => isDark ? darkSurfaceCard : lightSurfaceCard;
  static Color surfaceVariant(bool isDark) => isDark ? darkSurfaceVariant : lightSurfaceVariant;
  static Color elevatedSurface(bool isDark) => isDark ? darkSurfaceElevated : lightSurfaceElevated;
  static Color inputSurface(bool isDark) => isDark ? darkInputSurface : lightInputSurface;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color outline(bool isDark) => isDark ? darkOutline : lightOutline;
  static Color borderSubtle(bool isDark) => isDark ? darkBorderSubtle : lightBorderSubtle;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color textTertiary(bool isDark) => isDark ? darkTextTertiary : lightTextTertiary;
  static Color textDisabled(bool isDark) => isDark ? darkTextDisabled : lightTextDisabled;
  static Color textMuted(bool isDark) => isDark ? darkTextMuted : lightTextMuted;
  static Color iconPrimary(bool isDark) => isDark ? darkIconPrimary : lightIconPrimary;
  static Color iconSecondary(bool isDark) => isDark ? darkIconSecondary : lightIconSecondary;
  static Color selectedBackground(bool isDark) => isDark ? darkSelectedBackground : lightSelectedBackground;
  static Color selectedText(bool isDark) => isDark ? darkSelectedText : lightSelectedText;
  static Color divider(bool isDark) => isDark ? darkDivider : lightDivider;

  // Category Icon & Account Custom Accent Colors (Preserved for user categories)
  static const List<Color> categoryPalette = [
    Color(0xFF03323A), // Kals Brand Dark Petrol
    Color(0xFF23818D), // Kals Face Teal
    Color(0xFF059669), // Emerald
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Violet
    Color(0xFFDB2777), // Pink
    Color(0xFFEA580C), // Orange
    Color(0xFFD5A328), // Kals Beak Amber Gold
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0891B2), // Cyan
    Color(0xFF475569), // Slate
    Color(0xFFE11D48), // Crimson
    Color(0xFF65A30D), // Lime
  ];
}

/// Unified Single Brand Color Identity derived directly from official owl icon.
/// All legacy enum cases map to Kals Brand values to ensure 100% data compatibility with SQLite.
enum AppAccentColor {
  kalsBrand(
    'Kals Brand',
    Color(0xFF03323A),
    Color(0xFF23818D),
    Color(0xFFE2EFF1),
    Color(0xFF38A3B0),
    Color(0xFF0E2C33),
  ),
  slateBlue(
    'Kals Brand',
    Color(0xFF03323A),
    Color(0xFF23818D),
    Color(0xFFE2EFF1),
    Color(0xFF38A3B0),
    Color(0xFF0E2C33),
  ),
  teal(
    'Kals Brand',
    Color(0xFF03323A),
    Color(0xFF23818D),
    Color(0xFFE2EFF1),
    Color(0xFF38A3B0),
    Color(0xFF0E2C33),
  ),
  green(
    'Kals Brand',
    Color(0xFF03323A),
    Color(0xFF23818D),
    Color(0xFFE2EFF1),
    Color(0xFF38A3B0),
    Color(0xFF0E2C33),
  ),
  blue(
    'Kals Brand',
    Color(0xFF03323A),
    Color(0xFF23818D),
    Color(0xFFE2EFF1),
    Color(0xFF38A3B0),
    Color(0xFF0E2C33),
  ),
  purple(
    'Kals Brand',
    Color(0xFF03323A),
    Color(0xFF23818D),
    Color(0xFFE2EFF1),
    Color(0xFF38A3B0),
    Color(0xFF0E2C33),
  ),
  orange(
    'Kals Brand',
    Color(0xFF03323A),
    Color(0xFF23818D),
    Color(0xFFE2EFF1),
    Color(0xFF38A3B0),
    Color(0xFF0E2C33),
  );

  final String displayName;
  final Color primary;
  final Color primaryLight;
  final Color container;
  final Color darkPrimary;
  final Color darkContainer;

  const AppAccentColor(
    this.displayName,
    this.primary,
    this.primaryLight,
    this.container,
    this.darkPrimary,
    this.darkContainer,
  );
}
