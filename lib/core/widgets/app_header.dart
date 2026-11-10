import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final double? bottomHeight;
  final bool showBackButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.bottomHeight,
    this.showBackButton = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = backgroundColor ?? (isDark ? AppColors.darkSurface : theme.colorScheme.primary);

    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: borderRadius ??
            const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
        border: (backgroundColor == null && isDark) ? const Border(bottom: BorderSide(color: AppColors.darkBorderSubtle)) : null,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : headerColor.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding ??
          EdgeInsets.only(
            top: topPadding + 8,
            left: 16,
            right: 16,
            bottom: bottom != null ? 14 : 16,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: NavigationToolbar(
              leading: leading ??
                  ((showBackButton && Navigator.canPop(context))
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                          onPressed: () => Navigator.maybePop(context),
                          tooltip: 'Back',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        )
                      : null),
              middle: titleWidget ??
                  Padding(
                    padding: EdgeInsets.only(left: centerTitle ? 0 : 8),
                    child: Text(
                      title ?? '',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                      textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              trailing: actions != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: actions!,
                    )
                  : null,
              centerMiddle: centerTitle,
            ),
          ),

          if (bottom != null) ...[
            const SizedBox(height: 12),
            bottom!,
          ],
        ],
      ),
    );
  }
}