import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Clean, seamless startup container matching the native splash background
/// preventing any duplicate splash screens or flashes during initialization.
class AppSplashView extends StatelessWidget {
  const AppSplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: const SizedBox.shrink(),
    );
  }
}
