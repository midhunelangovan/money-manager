/// ISO 4217 Currency representation with display metadata.
/// Currency is never hardcoded and monetary calculations remain pure integer units.
class AppCurrency {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final int decimalDigits;
  final bool isSymbolPrefix;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    this.decimalDigits = 2,
    this.isSymbolPrefix = true,
  });

  static const AppCurrency inr = AppCurrency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    flag: '🇮🇳',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency usd = AppCurrency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    flag: '🇺🇸',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency eur = AppCurrency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    flag: '🇪🇺',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency gbp = AppCurrency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    flag: '🇬🇧',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency jpy = AppCurrency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    flag: '🇯🇵',
    decimalDigits: 0,
    isSymbolPrefix: true,
  );

  static const AppCurrency cad = AppCurrency(
    code: 'CAD',
    symbol: 'CA\$',
    name: 'Canadian Dollar',
    flag: '🇨🇦',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency aud = AppCurrency(
    code: 'AUD',
    symbol: 'AU\$',
    name: 'Australian Dollar',
    flag: '🇦🇺',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency sgd = AppCurrency(
    code: 'SGD',
    symbol: 'SG\$',
    name: 'Singapore Dollar',
    flag: '🇸🇬',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency aed = AppCurrency(
    code: 'AED',
    symbol: 'AED',
    name: 'UAE Dirham',
    flag: '🇦🇪',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency chf = AppCurrency(
    code: 'CHF',
    symbol: 'CHF',
    name: 'Swiss Franc',
    flag: '🇨🇭',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency sar = AppCurrency(
    code: 'SAR',
    symbol: 'SAR',
    name: 'Saudi Riyal',
    flag: '🇸🇦',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency cny = AppCurrency(
    code: 'CNY',
    symbol: 'CN¥',
    name: 'Chinese Yuan',
    flag: '🇨🇳',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const AppCurrency brl = AppCurrency(
    code: 'BRL',
    symbol: 'R\$',
    name: 'Brazilian Real',
    flag: '🇧🇷',
    decimalDigits: 2,
    isSymbolPrefix: true,
  );

  static const List<AppCurrency> supportedCurrencies = [
    inr,
    usd,
    eur,
    gbp,
    jpy,
    cad,
    aud,
    sgd,
    aed,
    chf,
    sar,
    cny,
    brl,
  ];

  static AppCurrency fromCode(String code) {
    final upper = code.toUpperCase().trim();
    for (final curr in supportedCurrencies) {
      if (curr.code == upper) return curr;
    }
    return inr; // Default fallback
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCurrency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
