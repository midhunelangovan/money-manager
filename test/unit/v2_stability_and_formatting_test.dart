import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/navigation/navigation_service.dart';
import 'package:kals_money_manager/core/utilities/indian_number_formatter.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';

void main() {
  group('IndianNumberFormatter Tests', () {
    test('formats units according to Indian numbering system', () {
      // 100 units = 1.00
      expect(IndianNumberFormatter.formatUnits(100), '1.00');

      // 1000 units = 10.00
      expect(IndianNumberFormatter.formatUnits(1000), '10.00');

      // 100000 units = 1,000.00
      expect(IndianNumberFormatter.formatUnits(100000), '1,000.00');

      // 1000000 units = 10,000.00
      expect(IndianNumberFormatter.formatUnits(1000000), '10,000.00');

      // 10000000 units = 1,00,000.00 (1 Lakh)
      expect(IndianNumberFormatter.formatUnits(10000000), '1,00,000.00');

      // 100000000 units = 10,00,000.00 (10 Lakhs)
      expect(IndianNumberFormatter.formatUnits(100000000), '10,00,000.00');

      // 1000000000 units = 1,00,00,000.00 (1 Crore)
      expect(IndianNumberFormatter.formatUnits(1000000000), '1,00,00,000.00');
    });

    test('parses Indian formatted strings to integer units', () {
      expect(IndianNumberFormatter.parseToUnits('1,000'), 100000);
      expect(IndianNumberFormatter.parseToUnits('1,00,000'), 10000000);
      expect(IndianNumberFormatter.parseToUnits('1,00,00,000'), 1000000000);
      expect(IndianNumberFormatter.parseToUnits('1,23,456.78'), 12345678);
      expect(IndianNumberFormatter.parseToUnits('500'), 50000);
      expect(IndianNumberFormatter.parseToUnits('0.50'), 50);
      expect(IndianNumberFormatter.parseToUnits(''), 0);
      expect(IndianNumberFormatter.parseToUnits('invalid'), 0);
    });

    test('IndianNumberTextInputFormatter formats text without cursor issues', () {
      final formatter = IndianNumberTextInputFormatter(maxDecimalDigits: 2);

      const oldValue = TextEditingValue(text: '1000', selection: TextSelection.collapsed(offset: 4));
      const newValue = TextEditingValue(text: '10000', selection: TextSelection.collapsed(offset: 5));

      final formatted = formatter.formatEditUpdate(oldValue, newValue);
      expect(formatted.text, '10,000');
      expect(formatted.selection.baseOffset, 6);
    });

    test('IndianNumberTextInputFormatter handles decimal inputs', () {
      final formatter = IndianNumberTextInputFormatter(maxDecimalDigits: 2);

      const oldValue = TextEditingValue(text: '1,000', selection: TextSelection.collapsed(offset: 5));
      const newValue = TextEditingValue(text: '1,000.5', selection: TextSelection.collapsed(offset: 7));

      final formatted = formatter.formatEditUpdate(oldValue, newValue);
      expect(formatted.text, '1,000.5');
    });
  });

  group('Multiple Receipt Attachments Tests', () {
    test('Transaction parses single and multi-path receipt strings seamlessly', () {
      final now = DateTime.now();

      // Single path (legacy)
      final txSingle = Transaction(
        id: 'tx_1',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_1',
        amount: const Money(units: 50000),
        date: now,
        description: 'Test Single',
        receiptPath: '/storage/receipt1.jpg',
        createdAt: now,
        updatedAt: now,
      );
      expect(txSingle.receiptPaths.length, 1);
      expect(txSingle.receiptPaths.first, '/storage/receipt1.jpg');

      // Multiple paths (up to 3) joined by pipe
      final txMulti = Transaction(
        id: 'tx_2',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_1',
        amount: const Money(units: 100000),
        date: now,
        description: 'Test Multi',
        receiptPath: '/storage/receipt1.jpg|/storage/receipt2.jpg|/storage/receipt3.jpg',
        createdAt: now,
        updatedAt: now,
      );
      expect(txMulti.receiptPaths.length, 3);
      expect(txMulti.receiptPaths[0], '/storage/receipt1.jpg');
      expect(txMulti.receiptPaths[1], '/storage/receipt2.jpg');
      expect(txMulti.receiptPaths[2], '/storage/receipt3.jpg');

      // Empty / null path
      final txEmpty = Transaction(
        id: 'tx_3',
        transactionType: CategoryType.expense,
        accountId: 'acc_1',
        categoryId: 'cat_1',
        amount: const Money(units: 10000),
        date: now,
        description: 'Test Empty',
        receiptPath: null,
        createdAt: now,
        updatedAt: now,
      );
      expect(txEmpty.receiptPaths.isEmpty, isTrue);
    });

    test('LedgerItem parses delimiter separated receipt paths', () {
      final now = DateTime.now();
      final item = LedgerItem(
        id: 'led_1',
        itemType: LedgerItemType.expense,
        amount: const Money(units: 50000),
        accountId: 'acc_1',
        categoryId: 'cat_1',
        date: now,
        description: 'Ledger item test',
        receiptPath: 'photo1.jpg|photo2.jpg',
        createdAt: now,
      );
      expect(item.receiptPaths.length, 2);
      expect(item.receiptPaths[0], 'photo1.jpg');
      expect(item.receiptPaths[1], 'photo2.jpg');
    });
  });

  group('Standard Context-Aware Navigation Tests', () {
    setUp(() {
      MainNavigationService.resetTabHistory();
    });

    test('MainNavigationService switches tabs directly without tab ping-ponging', () {
      expect(MainNavigationService.canPopTab, isFalse);
      expect(MainNavigationService.currentTab, 0);

      MainNavigationService.pushTab(1); // Navigated to Transactions
      expect(MainNavigationService.currentTab, 1);
      // Root level does not ping-pong through tab history
      expect(MainNavigationService.canPopTab, isFalse);
      expect(MainNavigationService.popTab(), isFalse);

      MainNavigationService.pushTab(2); // Navigated to Accounts
      expect(MainNavigationService.currentTab, 2);
      expect(MainNavigationService.canPopTab, isFalse);

      MainNavigationService.resetTabHistory(0);
      expect(MainNavigationService.currentTab, 0);
    });
  });
}
