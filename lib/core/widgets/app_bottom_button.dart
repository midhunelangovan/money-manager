import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable wide pill-shaped warm yellow action button matching the reference specification.
/// Centered horizontally with readable dark text, consistent elevation, and safe-area padding.
class AppBottomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double width;

  const AppBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBottom = MediaQuery.of(context).padding.bottom;
    final isEnabled = onPressed != null && !isLoading;

    final btnBg = backgroundColor ?? AppColors.floatingAction; // warm yellow #D5A328
    final btnFg = foregroundColor ?? const Color(0xFF1A2228); // readable dark charcoal

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: bottomInset > 0 ? bottomInset + 12 : navBottom + 16,
      ),
      child: Center(
        child: SizedBox(
          width: width,
          height: 48,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              disabledBackgroundColor: btnBg.withValues(alpha: 0.45),
              disabledForegroundColor: btnFg.withValues(alpha: 0.5),
              elevation: isEnabled ? 2 : 0,
              shadowColor: btnBg.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: btnFg,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? btnFg : btnFg.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
