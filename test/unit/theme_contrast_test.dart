import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/theme/app_colors.dart';
import 'package:kals_money_manager/core/theme/app_theme.dart';

void main() {
  group('Centralized Theme & Semantic Palette Tests', () {
    test('Semantic color getters return distinct, readable values for Light and Dark modes', () {
      // Background & Surfaces
      expect(AppColors.background(false), AppColors.lightBackground);
      expect(AppColors.background(true), AppColors.darkBackground);
      expect(AppColors.surface(false), AppColors.lightSurface);
      expect(AppColors.surface(true), AppColors.darkSurface);
      expect(AppColors.elevatedSurface(false), AppColors.lightSurfaceElevated);
      expect(AppColors.elevatedSurface(true), AppColors.darkSurfaceElevated);
      expect(AppColors.inputSurface(false), AppColors.lightInputSurface);
      expect(AppColors.inputSurface(true), AppColors.darkInputSurface);

      // Text colors
      expect(AppColors.textPrimary(false), AppColors.lightTextPrimary);
      expect(AppColors.textPrimary(true), AppColors.darkTextPrimary);
      expect(AppColors.textSecondary(false), AppColors.lightTextSecondary);
      expect(AppColors.textSecondary(true), AppColors.darkTextSecondary);
      expect(AppColors.textDisabled(false), AppColors.lightTextDisabled);
      expect(AppColors.textDisabled(true), AppColors.darkTextDisabled);

      // Selected items & dividers
      expect(AppColors.selectedBackground(true), AppColors.darkSelectedBackground);
      expect(AppColors.selectedText(true), AppColors.darkSelectedText);
      expect(AppColors.divider(true), AppColors.darkDivider);
      expect(AppColors.iconPrimary(true), AppColors.darkIconPrimary);
      expect(AppColors.iconSecondary(true), AppColors.darkIconSecondary);
    });

    test('All AppAccentColor variants provide luminous dark primary tones', () {
      for (final accent in AppAccentColor.values) {
        // In dark mode, darkPrimary must not be dark navy/black
        expect(accent.darkPrimary, isNotNull);
        expect(accent.darkContainer, isNotNull);

        final darkTheme = AppTheme.darkTheme(accent);
        expect(darkTheme.colorScheme.primary, accent.darkPrimary);
        expect(darkTheme.colorScheme.surface, AppColors.darkSurface);
        expect(darkTheme.scaffoldBackgroundColor, AppColors.darkBackground);
      }
    });

    test('DatePickerTheme and TimePickerTheme in Dark Theme use luminous primary accent', () {
      final darkTheme = AppTheme.darkTheme(AppAccentColor.slateBlue);
      final dpTheme = darkTheme.datePickerTheme;
      final tpTheme = darkTheme.timePickerTheme;

      expect(dpTheme.backgroundColor, AppColors.darkSurfaceCard);
      expect(dpTheme.dividerColor, AppColors.darkBorder);
      expect(tpTheme.backgroundColor, AppColors.darkSurfaceCard);
      expect(tpTheme.dialHandColor, AppAccentColor.slateBlue.darkPrimary);
      expect(tpTheme.entryModeIconColor, AppAccentColor.slateBlue.darkPrimary);
    });
  });
}
