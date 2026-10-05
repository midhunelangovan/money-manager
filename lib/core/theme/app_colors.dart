import 'package:flutter/material.dart';

class AppColors {
  // Primary / Brand Colors - Sophisticated Deep Slate Blue
  static const Color primary = Color(0xFF1E3A5F); // Deep Slate Blue
  static const Color primaryLight = Color(0xFF2B5282);
  static const Color primaryDark = Color(0xFF132842);
  static const Color primaryContainer = Color(0xFFE8EEF5);

  // Accent / Floating Button Color (Warm amber/orange)
  static const Color accentYellow = Color(0xFFEAA63B);
  static const Color floatingAction = Color(0xFFEAA63B);

  // Financial Status Colors
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
  static const Color lightBorder = Color(0xFFE5E4DE); // Subtle neutral warm border
  static const Color lightBorderSubtle = Color(0xFFEDEDE8); // Ultra subtle border
  static const Color lightTextPrimary = Color(0xFF1B1E24); // Crisp dark text
  static const Color lightTextSecondary = Color(0xFF5F6877); // Muted secondary text
  static const Color lightTextTertiary = Color(0xFF808B9D); // Tertiary label text
  static const Color lightTextMuted = Color(0xFF9EA7B5); // Muted placeholder text

  // Dark Palette - Matte Charcoal/Navy
  static const Color darkBackground = Color(0xFF0B111E); // Deep midnight slate
  static const Color darkSurface = Color(0xFF131D2E); // Dark surface
  static const Color darkSurfaceCard = Color(0xFF18253A); // Dark card surface
  static const Color darkSurfaceElevated = Color(0xFF1E2D44); // Elevated dark surface
  static const Color darkBorder = Color(0xFF283A55); // Subtle dark border
  static const Color darkBorderSubtle = Color(0xFF1E2E46); // Ultra subtle dark border
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Very light / crisp off-white (Slate-50)
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // High-contrast light gray (Slate-300)
  static const Color darkTextTertiary = Color(0xFFA6B4C9); // Highly readable medium-light gray (~5.8:1 ratio)
  static const Color darkTextMuted = Color(0xFF8899B0); // Clear, readable muted gray / placeholder (~4.8:1 ratio)

  // Category Icon & Account Custom Accent Colors
  static const List<Color> categoryPalette = [
    Color(0xFF1E3A5F), // Slate Blue
    Color(0xFF0F766E), // Teal
    Color(0xFF059669), // Emerald
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Violet
    Color(0xFFDB2777), // Pink
    Color(0xFFEA580C), // Orange
    Color(0xFFD97706), // Amber
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0891B2), // Cyan
    Color(0xFF475569), // Slate
    Color(0xFFE11D48), // Crimson
    Color(0xFF65A30D), // Lime
  ];
}

enum AppAccentColor {
  slateBlue('Slate Blue', Color(0xFF1E3A5F), Color(0xFF2B5282), Color(0xFFE8EEF5)),
  teal('Teal', Color(0xFF1E6D63), Color(0xFF2C8478), Color(0xFFE4F0EE)),
  green('Green', Color(0xFF1B6B42), Color(0xFF2E8B5B), Color(0xFFE2F3EA)),
  blue('Blue', Color(0xFF1D5C96), Color(0xFF2C74B3), Color(0xFFE2EDF7)),
  purple('Purple', Color(0xFF5B3E84), Color(0xFF7652A8), Color(0xFFECE4F5)),
  orange('Orange', Color(0xFFB85918), Color(0xFFD46F2A), Color(0xFFFBECE2));

  final String displayName;
  final Color primary;
  final Color primaryLight;
  final Color container;

  const AppAccentColor(this.displayName, this.primary, this.primaryLight, this.container);
}

