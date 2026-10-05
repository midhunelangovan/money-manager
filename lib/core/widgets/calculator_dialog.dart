import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CalculatorDialog extends StatefulWidget {
  final double initialValue;

  const CalculatorDialog({super.key, this.initialValue = 0});

  static Future<double?> show(BuildContext context, {double initialValue = 0}) {
    return showDialog<double>(
      context: context,
      builder: (ctx) => CalculatorDialog(initialValue: initialValue),
    );
  }

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldClearOnNextDigit = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue > 0) {
      _display = widget.initialValue.toStringAsFixed(widget.initialValue.truncateToDouble() == widget.initialValue ? 0 : 2);
    }
  }

  void _onDigit(String digit) {
    setState(() {
      if (_display == '0' || _shouldClearOnNextDigit) {
        _display = digit;
        _shouldClearOnNextDigit = false;
      } else {
        if (digit == '.' && _display.contains('.')) return;
        _display += digit;
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _shouldClearOnNextDigit = true;
    });
  }

  void _onEquals() {
    if (_firstOperand == null || _operator == null) return;
    final secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '−':
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
      case '*':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
      case '/':
        if (secondOperand != 0) {
          result = _firstOperand! / secondOperand;
        }
        break;
    }

    setState(() {
      _display = result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
      _firstOperand = null;
      _operator = null;
      _shouldClearOnNextDigit = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _operator = null;
      _shouldClearOnNextDigit = false;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF16202E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1722) : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),

            // Keypad
            Table(
              children: [
                TableRow(
                  children: [
                    _calcBtn('C', color: AppColors.expense, onTap: _onClear),
                    _calcBtn('⌫', onTap: _onBackspace),
                    _calcBtn('÷', isOp: true, onTap: () => _onOperator('÷')),
                    _calcBtn('×', isOp: true, onTap: () => _onOperator('×')),
                  ],
                ),
                TableRow(
                  children: [
                    _calcBtn('7', onTap: () => _onDigit('7')),
                    _calcBtn('8', onTap: () => _onDigit('8')),
                    _calcBtn('9', onTap: () => _onDigit('9')),
                    _calcBtn('−', isOp: true, onTap: () => _onOperator('−')),
                  ],
                ),
                TableRow(
                  children: [
                    _calcBtn('4', onTap: () => _onDigit('4')),
                    _calcBtn('5', onTap: () => _onDigit('5')),
                    _calcBtn('6', onTap: () => _onDigit('6')),
                    _calcBtn('+', isOp: true, onTap: () => _onOperator('+')),
                  ],
                ),
                TableRow(
                  children: [
                    _calcBtn('1', onTap: () => _onDigit('1')),
                    _calcBtn('2', onTap: () => _onDigit('2')),
                    _calcBtn('3', onTap: () => _onDigit('3')),
                    _calcBtn('=', color: AppColors.primary, onTap: _onEquals),
                  ],
                ),
                TableRow(
                  children: [
                    _calcBtn('0', onTap: () => _onDigit('0')),
                    _calcBtn('00', onTap: () => _onDigit('00')),
                    _calcBtn('.', onTap: () => _onDigit('.')),
                    _calcBtn('OK', color: AppColors.income, onTap: () {
                      final val = double.tryParse(_display) ?? 0;
                      Navigator.pop(context, val);
                    }),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcBtn(String label, {bool isOp = false, Color? color, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = color?.withValues(alpha: 0.15) ??
        (isOp
            ? AppColors.primary.withValues(alpha: 0.12)
            : (isDark ? const Color(0xFF222F42) : const Color(0xFFF1F5F4)));
    final btnTextColor = color ??
        (isOp
            ? AppColors.primary
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary));

    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: btnTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
