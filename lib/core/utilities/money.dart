import 'package:intl/intl.dart';
import '../constants/app_currency.dart';

/// Represents a monetary value stored in the smallest currency unit (e.g., paise/cents) as an [int].
/// Eliminates floating-point rounding errors in financial calculations.
class Money implements Comparable<Money> {
  /// The monetary amount in the smallest currency unit (e.g., 100 paise = 1.00 major unit).
  final int units;

  /// ISO 4217 Currency code (e.g., 'INR', 'USD', 'EUR').
  final String currencyCode;

  /// Currency symbol (e.g., '₹', '$', '€').
  final String currencySymbol;

  const Money({
    required this.units,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
  });

  /// Factory for creating Money directly from units.
  factory Money.fromUnits(
    int units, {
    String currencyCode = 'INR',
    String currencySymbol = '₹',
  }) =>
      Money(
        units: units,
        currencyCode: currencyCode,
        currencySymbol: currencySymbol,
      );

  /// Alias for units
  int get amountUnits => units;

  /// Factory for zero amount.
  const Money.zero({String currencyCode = 'INR', String currencySymbol = '₹'})
      : this(units: 0, currencyCode: currencyCode, currencySymbol: currencySymbol);

  /// Creates a [Money] from major units and minor units.
  factory Money.fromMajorAndMinor(
    int major,
    int minor, {
    String currencyCode = 'INR',
    String currencySymbol = '₹',
  }) {
    final sign = major < 0 ? -1 : 1;
    final totalUnits = (major.abs() * 100 + minor.abs()) * sign;
    return Money(
      units: totalUnits,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
  }

  /// Parses a string representation like "450.50", "1,000", "-50.25", "$ 250.00".
  /// Avoids floating-point parsing errors by splitting on decimal separator.
  static Money parse(
    String input, {
    String currencyCode = 'INR',
    String currencySymbol = '₹',
  }) {
    final clean = input
        .replaceAll(currencySymbol, '')
        .replaceAll(currencyCode, '')
        .replaceAll(',', '')
        .trim();

    if (clean.isEmpty) {
      return Money.zero(currencyCode: currencyCode, currencySymbol: currencySymbol);
    }

    final isNegative = clean.startsWith('-');
    final absClean = isNegative ? clean.substring(1).trim() : clean;

    final parts = absClean.split('.');
    final majorPart = int.tryParse(parts[0]) ?? 0;
    int minorPart = 0;

    if (parts.length > 1) {
      final minorStr = parts[1].padRight(2, '0').substring(0, 2);
      minorPart = int.tryParse(minorStr) ?? 0;
    }

    final totalUnits = (majorPart * 100 + minorPart) * (isNegative ? -1 : 1);
    return Money(
      units: totalUnits,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
  }

  /// Tries to parse, returns null if completely invalid format.
  static Money? tryParse(
    String input, {
    String currencyCode = 'INR',
    String currencySymbol = '₹',
  }) {
    try {
      return parse(input, currencyCode: currencyCode, currencySymbol: currencySymbol);
    } catch (_) {
      return null;
    }
  }

  // Arithmetic operations
  Money operator +(Money other) {
    _ensureSameCurrency(other);
    return Money(
      units: units + other.units,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
  }

  Money operator -(Money other) {
    _ensureSameCurrency(other);
    return Money(
      units: units - other.units,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
  }

  Money operator -() {
    return Money(
      units: -units,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
  }

  Money operator *(num multiplier) {
    return Money(
      units: (units * multiplier).round(),
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
  }

  bool get isZero => units == 0;
  bool get isPositive => units > 0;
  bool get isNegative => units < 0;

  Money abs() => Money(
        units: units.abs(),
        currencyCode: currencyCode,
        currencySymbol: currencySymbol,
      );

  void _ensureSameCurrency(Money other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError(
        'Cannot perform arithmetic on different currencies: $currencyCode and ${other.currencyCode}',
      );
    }
  }

  @override
  int compareTo(Money other) {
    _ensureSameCurrency(other);
    return units.compareTo(other.units);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          units == other.units &&
          currencyCode == other.currencyCode;

  @override
  int get hashCode => units.hashCode ^ currencyCode.hashCode;

  /// Returns major units as integer (e.g. 45050 -> 450).
  int get majorUnits => units ~/ 100;

  /// Returns minor units (e.g. 45050 -> 50).
  int get minorUnits => (units % 100).abs();

  /// Converts to standard double for display/charts ONLY.
  /// Never use this double for financial calculations or persistence.
  double toDoubleForDisplay() => units / 100.0;

  /// Formatted string respecting configured [AppCurrency] or default formatting.
  String format({
    AppCurrency? currency,
    bool includeSymbol = true,
  }) {
    final activeCurrency = currency ?? AppCurrency.fromCode(currencyCode);
    final isNegativeAmount = units < 0;
    final absUnits = units.abs();

    final major = absUnits ~/ 100;
    final minor = absUnits % 100;

    String formattedMajor;
    if (activeCurrency.code == 'INR') {
      formattedMajor = NumberFormat('#,##,##0', 'en_IN').format(major);
    } else {
      formattedMajor = NumberFormat('#,##0', 'en_US').format(major);
    }

    String formattedNumber;
    if (activeCurrency.decimalDigits > 0) {
      final formattedMinor = minor.toString().padLeft(activeCurrency.decimalDigits, '0');
      formattedNumber = '$formattedMajor.$formattedMinor';
    } else {
      formattedNumber = formattedMajor;
    }

    final sign = isNegativeAmount ? '-' : '';

    if (!includeSymbol) {
      return '$sign$formattedNumber';
    }

    if (activeCurrency.isSymbolPrefix) {
      return '$sign${activeCurrency.symbol} $formattedNumber';
    } else {
      return '$sign$formattedNumber ${activeCurrency.symbol}';
    }
  }

  @override
  String toString() => format();
}
