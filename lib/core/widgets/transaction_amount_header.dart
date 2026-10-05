import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_currency.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TransactionAmountHeader extends StatelessWidget {
  final TextEditingController controller;
  final AppCurrency currency;
  final Color accentColor;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCalculatorTap;

  const TransactionAmountHeader({
    super.key,
    required this.controller,
    required this.currency,
    required this.accentColor,
    this.autofocus = true,
    this.focusNode,
    this.onChanged,
    this.onCalculatorTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141D29) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Currency symbol on left
              Text(
                currency.symbol,
                style: AppTypography.displaySmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),

              // Large amount input field with autofocus & decimal numeric keypad
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: AppTypography.displaySmall.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTypography.displaySmall.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontWeight: FontWeight.w800,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: onChanged,
                ),
              ),

              // Currency Code (e.g. INR / USD)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currency.code,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Calculator Action Icon 🧮
              IconButton(
                icon: const Icon(Icons.calculate_outlined),
                tooltip: 'Calculator',
                color: accentColor,
                iconSize: 26,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: onCalculatorTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
