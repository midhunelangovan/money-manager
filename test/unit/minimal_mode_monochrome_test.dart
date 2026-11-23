import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/theme/app_colors.dart';
import 'package:kals_money_manager/core/theme/app_theme.dart';
import 'package:kals_money_manager/core/widgets/app_category_icon.dart';
import 'package:kals_money_manager/core/widgets/donut_chart.dart';

void main() {
  group('Minimal Mode Monochrome Palette & Theme Tests', () {
    tearDown(() {
      AppColors.isMinimalMode = false;
    });

    test('AppColors resolves standard colors when isMinimalMode is false', () {
      AppColors.isMinimalMode = false;

      expect(AppColors.background(false), equals(AppColors.lightBackground));
      expect(AppColors.background(true), equals(AppColors.darkBackground));
      expect(AppColors.surface(false), equals(AppColors.lightSurface));
      expect(AppColors.surface(true), equals(AppColors.darkSurface));
      expect(AppColors.textPrimary(false), equals(AppColors.lightTextPrimary));
      expect(AppColors.textPrimary(true), equals(AppColors.darkTextPrimary));
      expect(AppColors.textSecondary(false), equals(AppColors.lightTextSecondary));
      expect(AppColors.textSecondary(true), equals(AppColors.darkTextSecondary));
      expect(AppColors.border(false), equals(AppColors.lightBorder));
      expect(AppColors.border(true), equals(AppColors.darkBorder));

      // Category icon retains original color
      const originalColor = Color(0xFF2563EB);
      expect(AppColors.categoryIconBackground(originalColor, false), equals(originalColor));
      expect(AppColors.categoryIconGlyph(false), equals(Colors.white));
    });

    test('AppColors resolves proper unified monochrome palette in Light Minimal mode', () {
      AppColors.isMinimalMode = true;

      expect(AppColors.background(false), equals(AppColors.minimalLightBackground));
      expect(AppColors.surface(false), equals(AppColors.minimalLightSurface));
      expect(AppColors.surfaceCard(false), equals(AppColors.minimalLightSurfaceCard));
      expect(AppColors.textPrimary(false), equals(AppColors.minimalLightTextPrimary));
      expect(AppColors.textSecondary(false), equals(AppColors.minimalLightTextSecondary));
      expect(AppColors.border(false), equals(AppColors.minimalLightBorder));
      expect(AppColors.primaryAction(false), equals(AppColors.minimalLightPrimary));
      expect(AppColors.floatingActionButton(false), equals(AppColors.minimalLightPrimary));
      expect(AppColors.floatingActionButtonIcon(false), equals(Colors.white));

      // Light chart palette has 8 alternating contrast steps
      final palette = AppColors.chartPalette(false);
      expect(palette.length, equals(8));
      expect(palette, equals(AppColors.minimalDonutPaletteLight));

      // Progress bar treatment
      const originalColor = Color(0xFF2563EB);
      expect(AppColors.progressTrack(false), equals(AppColors.minimalLightBorder));
      expect(AppColors.progressIndicator(originalColor, false), equals(AppColors.minimalLightPrimary));

      // Category icon treatment: neutral container & charcoal glyph
      expect(AppColors.categoryIconBackground(originalColor, false), equals(AppColors.minimalLightSurfaceElevated));
      expect(AppColors.categoryIconGlyph(false), equals(AppColors.minimalLightTextPrimary));
      expect(AppColors.categoryIconBorder(false, false), equals(AppColors.minimalLightBorder));
      expect(AppColors.categoryIconBorder(false, true), equals(AppColors.minimalLightPrimary));
    });

    test('AppColors resolves proper unified monochrome palette in Dark Minimal mode', () {
      AppColors.isMinimalMode = true;

      expect(AppColors.background(true), equals(AppColors.minimalDarkBackground));
      expect(AppColors.surface(true), equals(AppColors.minimalDarkSurface));
      expect(AppColors.surfaceCard(true), equals(AppColors.minimalDarkSurfaceCard));
      expect(AppColors.textPrimary(true), equals(AppColors.minimalDarkTextPrimary));
      expect(AppColors.textSecondary(true), equals(AppColors.minimalDarkTextSecondary));
      expect(AppColors.border(true), equals(AppColors.minimalDarkBorder));
      expect(AppColors.primaryAction(true), equals(AppColors.minimalDarkPrimary));
      expect(AppColors.floatingActionButton(true), equals(AppColors.minimalDarkPrimary));
      expect(AppColors.floatingActionButtonIcon(true), equals(AppColors.minimalDarkBackground));

      // Dark chart palette
      final palette = AppColors.chartPalette(true);
      expect(palette.length, equals(8));
      expect(palette, equals(AppColors.minimalDonutPaletteDark));

      // Progress bar treatment
      const originalColor = Color(0xFF2563EB);
      expect(AppColors.progressTrack(true), equals(AppColors.minimalDarkBorderSubtle));
      expect(AppColors.progressIndicator(originalColor, true), equals(AppColors.minimalDarkPrimary));

      // Category icon treatment: dark neutral container & off-white glyph
      expect(AppColors.categoryIconBackground(originalColor, true), equals(AppColors.minimalDarkSurfaceElevated));
      expect(AppColors.categoryIconGlyph(true), equals(AppColors.minimalDarkTextPrimary));
      expect(AppColors.categoryIconBorder(true, false), equals(AppColors.minimalDarkBorder));
      expect(AppColors.categoryIconBorder(true, true), equals(AppColors.minimalDarkPrimary));
    });

    test('AppTheme builds coherent monochrome ThemeData for light and dark', () {
      final lightMinimalTheme = AppTheme.lightTheme(AppAccentColor.slateBlue, true);
      expect(lightMinimalTheme.scaffoldBackgroundColor, equals(AppColors.minimalLightBackground));
      expect(lightMinimalTheme.colorScheme.primary, equals(AppColors.minimalLightPrimary));
      expect(lightMinimalTheme.colorScheme.surface, equals(AppColors.minimalLightSurface));

      final darkMinimalTheme = AppTheme.darkTheme(AppAccentColor.slateBlue, true);
      expect(darkMinimalTheme.scaffoldBackgroundColor, equals(AppColors.minimalDarkBackground));
      expect(darkMinimalTheme.colorScheme.primary, equals(AppColors.minimalDarkPrimary));
      expect(darkMinimalTheme.colorScheme.surface, equals(AppColors.minimalDarkSurface));
    });

    testWidgets('AppCategoryIcon renders monochrome styling when isMinimalMode is true', (tester) async {
      AppColors.isMinimalMode = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(AppAccentColor.slateBlue, true),
          home: const Scaffold(
            body: Center(
              child: AppCategoryIcon(
                icon: Icons.shopping_bag_outlined,
                color: Color(0xFFEF4444), // Stored red color
                size: 40,
                iconSize: 20,
              ),
            ),
          ),
        ),
      );

      // Verify widget builds without error
      expect(find.byType(AppCategoryIcon), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.shopping_bag_outlined));
      expect(iconWidget.color, equals(AppColors.minimalLightTextPrimary));
    });

    testWidgets('DonutChart renders with monochrome palette in Minimal Mode', (tester) async {
      AppColors.isMinimalMode = true;

      final segments = [
        const DonutSegment(
          label: 'Food',
          value: 5000,
          color: Color(0xFFEF4444), // Colorful input from DB
          percentage: 50.0,
        ),
        const DonutSegment(
          label: 'Transport',
          value: 3000,
          color: Color(0xFF3B82F6), // Colorful input from DB
          percentage: 30.0,
        ),
        const DonutSegment(
          label: 'Utilities',
          value: 2000,
          color: Color(0xFF10B981), // Colorful input from DB
          percentage: 20.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(AppAccentColor.slateBlue, true),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: DonutChart(
                  segments: segments,
                  centerAmount: 'Rs. 10,000',
                  centerLabel: 'Total',
                ),
              ),
            ),
          ),
        ),
      );

      // Verify chart renders successfully
      expect(find.byType(DonutChart), findsOneWidget);
      expect(find.text('Rs. 10,000'), findsOneWidget);
    });

    testWidgets('AppCategoryIcon overrides explicit background in Minimal Mode and restores when disabled', (tester) async {
      AppColors.isMinimalMode = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppCategoryIcon(
                icon: Icons.fastfood_rounded,
                color: const Color(0xFFEF4444),
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                size: 44,
                iconSize: 24,
              ),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.fastfood_rounded));
      expect(icon.color, equals(AppColors.minimalLightTextPrimary));

      // Disable minimal mode
      AppColors.isMinimalMode = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppCategoryIcon(
                icon: Icons.fastfood_rounded,
                color: const Color(0xFFEF4444),
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                size: 44,
                iconSize: 24,
              ),
            ),
          ),
        ),
      );

      final restoredIcon = tester.widget<Icon>(find.byIcon(Icons.fastfood_rounded));
      expect(restoredIcon.color, equals(Colors.white));
    });
  });
}
