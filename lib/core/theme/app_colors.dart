import 'package:flutter/material.dart';

class AppColors {
  /// Global runtime Minimal Mode flag, kept in sync with SettingsProvider
  static bool isMinimalMode = false;

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

  // Financial Status Colors (Semantic - Preserved for clarity in standard mode)
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

  // Standard Light Palette - Warm matte paper off-white / light-gray
  static const Color lightBackground = Color(0xFFF6F5F2);
  static const Color lightSurface = Color(0xFFFAFAF7);
  static const Color lightSurfaceCard = Color(0xFFFCFCFA);
  static const Color lightSurfaceElevated = Color(0xFFEFEFEA);
  static const Color lightSurfaceVariant = Color(0xFFEFEFEA);
  static const Color lightInputSurface = Color(0xFFEFEFEA);
  static const Color lightBorder = Color(0xFFE5E4DE);
  static const Color lightOutline = Color(0xFFE5E4DE);
  static const Color lightBorderSubtle = Color(0xFFEDEDE8);
  static const Color lightTextPrimary = Color(0xFF1B1E24);
  static const Color lightTextSecondary = Color(0xFF5F6877);
  static const Color lightTextTertiary = Color(0xFF808B9D);
  static const Color lightTextMuted = Color(0xFF9EA7B5);
  static const Color lightTextDisabled = Color(0xFFB0B7C3);
  static const Color lightIconPrimary = Color(0xFF1B1E24);
  static const Color lightIconSecondary = Color(0xFF5F6877);
  static const Color lightSelectedBackground = Color(0xFFE2EFF1);
  static const Color lightSelectedText = Color(0xFF03323A);
  static const Color lightDivider = Color(0xFFE5E4DE);

  // Standard Dark Palette - Deep midnight petrol slate
  static const Color darkBackground = Color(0xFF071417);
  static const Color darkSurface = Color(0xFF0E1E22);
  static const Color darkSurfaceCard = Color(0xFF14272D);
  static const Color darkSurfaceElevated = Color(0xFF1B3239);
  static const Color darkSurfaceVariant = Color(0xFF1B3239);
  static const Color darkInputSurface = Color(0xFF112227);
  static const Color darkBorder = Color(0xFF1F3D45);
  static const Color darkOutline = Color(0xFF1F3D45);
  static const Color darkBorderSubtle = Color(0xFF162E34);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFFA6B4C9);
  static const Color darkTextMuted = Color(0xFF8899B0);
  static const Color darkTextDisabled = Color(0xFF64748B);
  static const Color darkIconPrimary = Color(0xFFF8FAFC);
  static const Color darkIconSecondary = Color(0xFF94A3B8);
  static const Color darkPrimary = Color(0xFF38A3B0);
  static const Color darkSelectedBackground = Color(0xFF143037);
  static const Color darkSelectedText = Color(0xFFF8FAFC);
  static const Color darkDivider = Color(0xFF1F3D45);

  // =========================================================================
  // CENTRALIZED MINIMAL MODE MONOCHROME PALETTE (Section 1)
  // Dedicated, unified grayscale design system
  // =========================================================================

  // Light Minimal Monochrome
  static const Color minimalLightBackground = Color(0xFFF6F7F9);
  static const Color minimalLightSecondaryBackground = Color(0xFFECEEF2);
  static const Color minimalLightSurface = Color(0xFFFFFFFF);
  static const Color minimalLightSurfaceCard = Color(0xFFFFFFFF);
  static const Color minimalLightSurfaceElevated = Color(0xFFF1F2F5);
  static const Color minimalLightInputSurface = Color(0xFFF1F2F5);
  static const Color minimalLightBorder = Color(0xFFE2E4E8);
  static const Color minimalLightBorderSubtle = Color(0xFFECEEF2);
  static const Color minimalLightDivider = Color(0xFFE2E4E8);
  static const Color minimalLightTextPrimary = Color(0xFF18181B);
  static const Color minimalLightTextSecondary = Color(0xFF52525B);
  static const Color minimalLightTextTertiary = Color(0xFF71717A);
  static const Color minimalLightTextDisabled = Color(0xFFA1A1AA);
  static const Color minimalLightTextMuted = Color(0xFF8E8E93);
  static const Color minimalLightIconPrimary = Color(0xFF18181B);
  static const Color minimalLightIconSecondary = Color(0xFF71717A);
  static const Color minimalLightPrimary = Color(0xFF18181B);
  static const Color minimalLightSecondary = Color(0xFF3F3F46);
  static const Color minimalLightPrimaryContainer = Color(0xFFE4E4E7);
  static const Color minimalLightSelectedBackground = Color(0xFFE4E4E7);
  static const Color minimalLightSelectedText = Color(0xFF18181B);

  // Dark Minimal Monochrome
  static const Color minimalDarkBackground = Color(0xFF111113);
  static const Color minimalDarkSecondaryBackground = Color(0xFF18181B);
  static const Color minimalDarkSurface = Color(0xFF1C1C20);
  static const Color minimalDarkSurfaceCard = Color(0xFF1C1C20);
  static const Color minimalDarkSurfaceElevated = Color(0xFF242429);
  static const Color minimalDarkInputSurface = Color(0xFF242429);
  static const Color minimalDarkBorder = Color(0xFF2B2B32);
  static const Color minimalDarkBorderSubtle = Color(0xFF232328);
  static const Color minimalDarkDivider = Color(0xFF2B2B32);
  static const Color minimalDarkTextPrimary = Color(0xFFF4F4F6);
  static const Color minimalDarkTextSecondary = Color(0xFFA1A1AA);
  static const Color minimalDarkTextTertiary = Color(0xFF71717A);
  static const Color minimalDarkTextDisabled = Color(0xFF52525B);
  static const Color minimalDarkTextMuted = Color(0xFF71717A);
  static const Color minimalDarkIconPrimary = Color(0xFFF4F4F6);
  static const Color minimalDarkIconSecondary = Color(0xFF71717A);
  static const Color minimalDarkPrimary = Color(0xFFF4F4F6);
  static const Color minimalDarkSecondary = Color(0xFFD4D4D8);
  static const Color minimalDarkPrimaryContainer = Color(0xFF27272E);
  static const Color minimalDarkSelectedBackground = Color(0xFF27272E);
  static const Color minimalDarkSelectedText = Color(0xFFF4F4F6);

  // Coordinated Monochrome Chart Palettes (Section 4)
  static const List<Color> minimalDonutPaletteLight = [
    Color(0xFF18181B), // 1. Dark charcoal
    Color(0xFF8E8E93), // 2. Medium neutral grey
    Color(0xFF3F3F46), // 3. Slate dark grey
    Color(0xFFB0B0B8), // 4. Soft light grey
    Color(0xFF52525B), // 5. Medium-dark grey
    Color(0xFFD4D4D8), // 6. Pale grey
    Color(0xFF71717A), // 7. Intermediate grey
    Color(0xFF27272A), // 8. Deep charcoal
  ];

  static const List<Color> minimalDonutPaletteDark = [
    Color(0xFFF4F4F6), // 1. Off-white
    Color(0xFF52525B), // 2. Medium-dark grey
    Color(0xFFD4D4D8), // 3. Pale grey
    Color(0xFF3F3F46), // 4. Deep slate
    Color(0xFFA1A1AA), // 5. Medium grey
    Color(0xFF27272E), // 6. Charcoal
    Color(0xFF71717A), // 7. Intermediate grey
    Color(0xFFE4E4E7), // 8. Light off-white
  ];

  // Category Icon & Account Custom Accent Colors (Preserved for standard mode)
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

  // Semantic Helper Getters with Minimal Mode Support
  static Color background(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkBackground : minimalLightBackground) : (isDark ? darkBackground : lightBackground);
  static Color surface(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkSurface : minimalLightSurface) : (isDark ? darkSurface : lightSurface);
  static Color surfaceCard(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkSurfaceCard : minimalLightSurfaceCard) : (isDark ? darkSurfaceCard : lightSurfaceCard);
  static Color surfaceVariant(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkSurfaceElevated : minimalLightSurfaceElevated) : (isDark ? darkSurfaceVariant : lightSurfaceVariant);
  static Color elevatedSurface(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkSurfaceElevated : minimalLightSurfaceElevated) : (isDark ? darkSurfaceElevated : lightSurfaceElevated);
  static Color inputSurface(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkInputSurface : minimalLightInputSurface) : (isDark ? darkInputSurface : lightInputSurface);
  static Color border(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkBorder : minimalLightBorder) : (isDark ? darkBorder : lightBorder);
  static Color outline(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkBorder : minimalLightBorder) : (isDark ? darkOutline : lightOutline);
  static Color borderSubtle(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkBorderSubtle : minimalLightBorderSubtle) : (isDark ? darkBorderSubtle : lightBorderSubtle);
  static Color textPrimary(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkTextPrimary : minimalLightTextPrimary) : (isDark ? darkTextPrimary : lightTextPrimary);
  static Color textSecondary(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkTextSecondary : minimalLightTextSecondary) : (isDark ? darkTextSecondary : lightTextSecondary);
  static Color textTertiary(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkTextTertiary : minimalLightTextTertiary) : (isDark ? darkTextTertiary : lightTextTertiary);
  static Color textDisabled(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkTextDisabled : minimalLightTextDisabled) : (isDark ? darkTextDisabled : lightTextDisabled);
  static Color textMuted(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkTextMuted : minimalLightTextMuted) : (isDark ? darkTextMuted : lightTextMuted);
  static Color iconPrimary(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkIconPrimary : minimalLightIconPrimary) : (isDark ? darkIconPrimary : lightIconPrimary);
  static Color iconSecondary(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkIconSecondary : minimalLightIconSecondary) : (isDark ? darkIconSecondary : lightIconSecondary);
  static Color selectedBackground(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkSelectedBackground : minimalLightSelectedBackground) : (isDark ? darkSelectedBackground : lightSelectedBackground);
  static Color selectedText(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkSelectedText : minimalLightSelectedText) : (isDark ? darkSelectedText : lightSelectedText);
  static Color divider(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkDivider : minimalLightDivider) : (isDark ? darkDivider : lightDivider);

  static Color primaryAction(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkPrimary : minimalLightPrimary) : (isDark ? darkPrimary : primary);

  static Color floatingActionButton(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkPrimary : minimalLightPrimary) : floatingAction;

  static Color floatingActionButtonIcon(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkBackground : Colors.white) : const Color(0xFF1B1E24);

  static Color incomeColor(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkTextPrimary : minimalLightTextPrimary) : income;

  static Color expenseColor(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkTextSecondary : minimalLightTextSecondary) : expense;

  static Color transferColor(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkTextTertiary : minimalLightTextTertiary) : transfer;

  static Color primaryContainerColor(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkPrimaryContainer : minimalLightPrimaryContainer) : (isDark ? darkSurfaceElevated : primaryContainer);

  static Color progressTrack(bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkBorderSubtle : minimalLightBorder) : (isDark ? darkSurfaceElevated : lightSelectedBackground);

  static Color progressIndicator(Color? originalColor, bool isDark) =>
      isMinimalMode ? (isDark ? minimalDarkPrimary : minimalLightPrimary) : (originalColor ?? (isDark ? darkPrimary : primary));

  static Color categoryIconBackground(Color? originalColor, bool isDark) {
    if (isMinimalMode) {
      return isDark ? minimalDarkSurfaceElevated : minimalLightSurfaceElevated;
    }
    return originalColor ?? (isDark ? darkSurfaceElevated : lightSurfaceElevated);
  }

  static Color categoryIconGlyph(bool isDark) {
    if (isMinimalMode) {
      return isDark ? minimalDarkTextPrimary : minimalLightTextPrimary;
    }
    return Colors.white;
  }

  static Color categoryIconBorder(bool isDark, bool isSelected) {
    if (isMinimalMode) {
      if (isSelected) return isDark ? minimalDarkPrimary : minimalLightPrimary;
      return isDark ? minimalDarkBorder : minimalLightBorder;
    }
    return isDark ? darkPrimary : primary;
  }

  static Color accountIconColor(Color? originalColor, bool isDark) {
    if (isMinimalMode) {
      return isDark ? minimalDarkTextPrimary : minimalLightTextPrimary;
    }
    return originalColor ?? (isDark ? darkPrimary : primary);
  }

  static Color accountIconBackground(Color? originalColor, bool isDark) {
    if (isMinimalMode) {
      return isDark ? minimalDarkSurfaceElevated : minimalLightSurfaceElevated;
    }
    final c = originalColor ?? (isDark ? darkPrimary : primary);
    return c.withValues(alpha: 0.12);
  }

  static List<Color> chartPalette(bool isDark) {
    if (isMinimalMode) {
      return isDark ? minimalDonutPaletteDark : minimalDonutPaletteLight;
    }
    return categoryPalette;
  }
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
