import 'package:flutter/services.dart';

/// Centralized Indian Number Formatting utility.
/// Formats numbers using standard Indian grouping:
/// - 1,000
/// - 10,000
/// - 1,00,000 (Lakh)
/// - 10,00,000
/// - 1,00,00,000 (Crore)
///
/// Preserves decimals, negative values, and integer paise/cents units.
class IndianNumberFormatter {
  /// Formats an integer digit string using Indian grouping.
  static String formatIntegerString(String integerDigits) {
    if (integerDigits.isEmpty) return '';

    final isNegative = integerDigits.startsWith('-');
    String digits = isNegative ? integerDigits.substring(1) : integerDigits;

    // Preserve '0' if string is just '0'
    if (digits == '0') return isNegative ? '-0' : '0';

    // Remove leading zeros while preserving at least one digit
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    if (digits.length <= 3) {
      return isNegative ? '-$digits' : digits;
    }

    final last3 = digits.substring(digits.length - 3);
    final remaining = digits.substring(0, digits.length - 3);

    final buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    buffer.write(',');
    buffer.write(last3);

    return isNegative ? '-${buffer.toString()}' : buffer.toString();
  }

  /// Formats any raw numeric string (e.g. "1000", "100000.50", "-250000").
  static String formatRawString(String input, {bool preserveTrailingDot = true}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    final isNegative = trimmed.startsWith('-');
    final clean = trimmed.replaceAll('-', '').replaceAll(',', '');

    final dotIndex = clean.indexOf('.');
    if (dotIndex == -1) {
      final formatted = formatIntegerString(clean);
      return isNegative ? '-$formatted' : formatted;
    }

    final integerPart = clean.substring(0, dotIndex);
    final decimalPart = clean.substring(dotIndex + 1);

    final formattedInt = formatIntegerString(integerPart.isEmpty ? '0' : integerPart);
    final sign = isNegative ? '-' : '';

    if (decimalPart.isEmpty && preserveTrailingDot) {
      return '$sign$formattedInt.';
    }

    return '$sign$formattedInt.$decimalPart';
  }

  /// Formats integer units (e.g. 100000 units = 1,000.00).
  static String formatUnits(
    int units, {
    bool includeDecimals = true,
    bool trimZeroDecimals = false,
  }) {
    final isNegative = units < 0;
    final absUnits = units.abs();
    final major = absUnits ~/ 100;
    final minor = absUnits % 100;

    final formattedMajor = formatIntegerString(major.toString());
    final sign = isNegative ? '-' : '';

    if (!includeDecimals) {
      return '$sign$formattedMajor';
    }

    if (trimZeroDecimals && minor == 0) {
      return '$sign$formattedMajor';
    }

    final formattedMinor = minor.toString().padLeft(2, '0');
    return '$sign$formattedMajor.$formattedMinor';
  }

  /// Formats a double/num amount.
  static String formatAmount(
    num amount, {
    int decimalDigits = 2,
    bool trimZeroDecimals = false,
  }) {
    final units = (amount * 100).round();
    return formatUnits(
      units,
      includeDecimals: decimalDigits > 0,
      trimZeroDecimals: trimZeroDecimals,
    );
  }

  /// Cleans formatted input string by stripping commas and currency symbols.
  static String clean(String input) {
    return input
        .replaceAll('₹', '')
        .replaceAll('INR', '')
        .replaceAll('\$', '')
        .replaceAll('€', '')
        .replaceAll('£', '')
        .replaceAll(',', '')
        .trim();
  }

  /// Parses input string into integer units (e.g. "1,000.50" -> 100050).
  static int parseToUnits(String input) {
    final cleaned = clean(input);
    if (cleaned.isEmpty) return 0;

    final isNegative = cleaned.startsWith('-');
    final absClean = isNegative ? cleaned.substring(1).trim() : cleaned;

    final parts = absClean.split('.');
    final major = int.tryParse(parts[0]) ?? 0;
    int minor = 0;
    if (parts.length > 1) {
      final minorStr = parts[1].padRight(2, '0').substring(0, 2);
      minor = int.tryParse(minorStr) ?? 0;
    }

    final total = major * 100 + minor;
    return isNegative ? -total : total;
  }

  /// Parses input string into standard double.
  static double parseToDouble(String input) {
    final cleaned = clean(input);
    return double.tryParse(cleaned) ?? 0.0;
  }
}

/// TextInputFormatter that formats text as Indian digit grouping in real time
/// without moving or jumping the cursor unexpectedly.
class IndianNumberTextInputFormatter extends TextInputFormatter {
  final int maxDecimalDigits;

  const IndianNumberTextInputFormatter({this.maxDecimalDigits = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow single leading minus if negative allowed
    final isNegative = newValue.text.startsWith('-');
    String raw = newValue.text.replaceAll(',', '');
    if (isNegative) {
      raw = raw.substring(1);
    }

    // Check for valid decimal format (digits and at most 1 decimal point)
    final regExp = RegExp('^\\d*\\.?\\d{0,$maxDecimalDigits}\$');
    if (!regExp.hasMatch(raw)) {
      return oldValue;
    }

    // Count how many non-comma characters appear before the cursor in newValue
    int nonCommaCountBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.baseOffset && i < newValue.text.length; i++) {
      if (newValue.text[i] != ',') {
        nonCommaCountBeforeCursor++;
      }
    }

    // Format raw string
    final dotIndex = raw.indexOf('.');
    String integerPart = dotIndex == -1 ? raw : raw.substring(0, dotIndex);
    final decimalPart = dotIndex == -1 ? null : raw.substring(dotIndex + 1);

    String formattedInt = IndianNumberFormatter.formatIntegerString(integerPart);
    if (formattedInt.isEmpty && dotIndex != -1) {
      formattedInt = '0';
    }

    String formattedResult;
    if (decimalPart != null) {
      formattedResult = '${isNegative ? '-' : ''}$formattedInt.$decimalPart';
    } else {
      formattedResult = '${isNegative ? '-' : ''}$formattedInt';
    }

    // Determine new cursor offset such that nonCommaCountBeforeCursor characters precede it
    int newCursorOffset = 0;
    int nonCommaCount = 0;
    for (int i = 0; i < formattedResult.length; i++) {
      if (nonCommaCount == nonCommaCountBeforeCursor) {
        newCursorOffset = i;
        break;
      }
      if (formattedResult[i] != ',') {
        nonCommaCount++;
      }
      newCursorOffset = i + 1;
    }

    // Clamp cursor offset
    newCursorOffset = newCursorOffset.clamp(0, formattedResult.length);

    return TextEditingValue(
      text: formattedResult,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}

