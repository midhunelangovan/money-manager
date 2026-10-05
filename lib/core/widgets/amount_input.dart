import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final ValueChanged<String>? onChanged;
  final Color? color;
  final String? label;

  const AmountInputField({
    super.key,
    required this.controller,
    this.currencySymbol = '₹',
    this.onChanged,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activeColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currencySymbol,
                style: AppTypography.amountLarge.copyWith(
                  color: activeColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: AppTypography.amountLarge.copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
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
            ],
          ),
        ],
      ),
    );
  }
}
