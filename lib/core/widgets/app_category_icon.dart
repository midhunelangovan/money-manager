import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable, reference-matched category icon component.
///
/// Features circular matte backgrounds, consistent white outlined illustrations,
/// and a distinctive selected state with a thin brand-colored border and a small checkmark.
class AppCategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;
  final bool isSelected;
  final bool showBackground;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppCategoryIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 50.0,
    this.iconSize = 28.0,
    this.isSelected = false,
    this.showBackground = true,
    this.backgroundColor,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMinimal = AppColors.isMinimalMode;

    final primaryColor = isMinimal
        ? (isDark ? AppColors.minimalDarkPrimary : AppColors.minimalLightPrimary)
        : (isDark ? AppColors.darkPrimary : AppColors.primary);
    final surfaceColor = AppColors.background(isDark);

    final isCircle = borderRadius == null;

    final defaultBg = isMinimal
        ? (showBackground
            ? (isDark ? AppColors.minimalDarkSurfaceElevated : AppColors.minimalLightSurfaceElevated)
            : Colors.transparent)
        : (backgroundColor ??
            (showBackground
                ? AppColors.categoryIconBackground(color, isDark)
                : Colors.transparent));

    final glyphColor = isMinimal
        ? AppColors.categoryIconGlyph(isDark)
        : Colors.white;

    final borderDecoration = isSelected
        ? Border.all(
            color: primaryColor,
            width: 2.0,
          )
        : (isMinimal && showBackground
            ? Border.all(
                color: isDark ? AppColors.minimalDarkBorder : AppColors.minimalLightBorder,
                width: 1.0,
              )
            : null);

    Widget circleContainer = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: defaultBg,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : borderRadius,
        border: borderDecoration,
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: glyphColor,
        ),
      ),
    );

    Widget content;
    if (isSelected) {
      content = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          circleContainer,
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: surfaceColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: isMinimal
                      ? (isDark ? AppColors.minimalDarkBackground : Colors.white)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      content = circleContainer;
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: isCircle ? const CircleBorder() : null,
        borderRadius: isCircle ? null : borderRadius,
        child: content,
      );
    }

    return content;
  }
}
