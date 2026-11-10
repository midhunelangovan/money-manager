import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Border? border;
  final double borderRadius;
  final double? width;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.color,
    this.border,
    this.borderRadius = 16,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Widget content = Container(
      width: width,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: defaultBorder, width: 1),
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
