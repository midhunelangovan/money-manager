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
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surfaceColor = isDark ? AppColors.darkBackground : Colors.white;

    final effectiveColor = color ?? const Color(0xFF475569);
    final isCircle = borderRadius == null;

    final defaultBg = backgroundColor ??
        (showBackground
            ? effectiveColor
            : Colors.transparent);

    Widget circleContainer = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: defaultBg,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : borderRadius,
        border: isSelected
            ? Border.all(
                color: primaryColor,
                width: 2.0,
              )
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white,
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
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: Colors.white,
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
