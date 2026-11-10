import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final Border? border;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.border,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final effectiveBg = backgroundColor ??
        (isDark ? AppColors.darkSurfaceElevated : primaryColor.withValues(alpha: 0.18));
    final effectiveText = textColor ?? (isDark ? AppColors.darkTextPrimary : primaryColor);
    final calcFontSize = fontSize ?? (size * 0.4);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBg,
        border: border,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: effectiveText,
            fontSize: calcFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    return avatar;
  }
}
