import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/constants/app_currency.dart';
import 'package:kals_money_manager/core/utilities/money.dart';

void main() {
  group('Money Value Object & Integer Arithmetic Tests', () {
    test('Correctly parses major and minor units into exact integer units (paise/cents)', () {
      final m1 = Money.parse('450.50');
      expect(m1.units, equals(45050));
      expect(m1.majorUnits, equals(450));
      expect(m1.minorUnits, equals(50));
      expect(m1.format(includeSymbol: false), equals('450.50'));

      final m2 = Money.parse('1000');
      expect(m2.units, equals(100000));

      final m3 = Money.parse('₹ 12,34,567.89');
      expect(m3.units, equals(123456789));

      final m4 = Money.parse('-50.25');
      expect(m4.units, equals(-5025));
    });

    test('Zero floating-point inaccuracies in addition and subtraction', () {
      // 0.1 + 0.2 != 0.3 in IEEE 754 floating point (0.30000000000000004)
      // But in integer Money: 10 + 20 = 30 exactly!
      final tenPaise = Money.parse('0.10');
      final twentyPaise = Money.parse('0.20');
      final sum = tenPaise + twentyPaise;
      expect(sum.units, equals(30));
      expect(sum.format(includeSymbol: false), equals('0.30'));

      final m1 = Money.parse('100.50');
      final m2 = Money.parse('50.25');
      final diff = m1 - m2;
      expect(diff.units, equals(5025));
      expect(diff.format(includeSymbol: false), equals('50.25'));
    });

    test('Multiplication with rounding', () {
      final base = Money.parse('100.00');
      final result = base * 1.18; // 18% GST
      expect(result.units, equals(11800));
      expect(result.format(includeSymbol: false), equals('118.00'));
    });

    test('Comparisons work deterministically', () {
      final m1 = Money.parse('100.00');
      final m2 = Money.parse('200.00');
      final m3 = Money.parse('100.00');

      expect(m1 < m2, isTrue);
      expect(m2 > m1, isTrue);
      expect(m1 == m3, isTrue);
      expect(m1 <= m3, isTrue);
    });

    test('Currency mismatch throws ArgumentError', () {
      final inr = Money(units: 1000, currencyCode: 'INR');
      final usd = Money(units: 1000, currencyCode: 'USD');

      expect(() => inr + usd, throwsArgumentError);
    });

    test('Formats correctly according to configured AppCurrency metadata', () {
      final money = Money.parse('1250.75');

      // INR formatting
      expect(money.format(currency: AppCurrency.inr), equals('₹ 1,250.75'));

      // USD formatting
      expect(money.format(currency: AppCurrency.usd), equals('\$ 1,250.75'));

      // EUR formatting
      expect(money.format(currency: AppCurrency.eur), equals('€ 1,250.75'));

      // GBP formatting
      expect(money.format(currency: AppCurrency.gbp), equals('£ 1,250.75'));

      // JPY formatting (0 decimal digits)
      expect(money.format(currency: AppCurrency.jpy), equals('¥ 1,250'));
    });

    test('AppCurrency lookup resolves standard ISO 4217 codes', () {
      expect(AppCurrency.fromCode('USD'), equals(AppCurrency.usd));
      expect(AppCurrency.fromCode('eur'), equals(AppCurrency.eur));
      expect(AppCurrency.fromCode('GBP'), equals(AppCurrency.gbp));
      expect(AppCurrency.fromCode('JPY'), equals(AppCurrency.jpy));
      expect(AppCurrency.fromCode('INVALID'), equals(AppCurrency.inr)); // fallback
    });
  });
}
