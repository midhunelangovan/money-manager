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

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.bottomHeight,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? AppColors.darkSurface : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        border: isDark ? const Border(bottom: BorderSide(color: AppColors.darkBorderSubtle)) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : headerColor.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: topPadding + 8,
        left: 16,
        right: 16,
        bottom: bottom != null ? 16 : 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leading != null)
                leading!
              else if (showBackButton && Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              else
                const SizedBox(width: 4),

              Expanded(
                child: titleWidget ??
                    Text(
                      title ?? '',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              ),

              if (actions != null)
                Row(mainAxisSize: MainAxisSize.min, children: actions!)
              else
                const SizedBox(width: 40),
            ],
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
