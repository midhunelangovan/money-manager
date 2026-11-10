import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/theme/app_colors.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/features/accounts/domain/entities/account.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/categories/presentation/providers/category_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kals_money_manager/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:kals_money_manager/features/transfers/presentation/providers/transfer_provider.dart';
import 'package:provider/provider.dart';

class MockAccountProvider extends ChangeNotifier implements AccountProvider {
  @override
  List<Account> accounts = [
    Account(
      id: 'acc-1',
      name: 'Cash',
      accountType: AccountType.cash,
      openingBalance: Money.fromUnits(100000),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  List<AccountWithBalance> accountsWithBalances = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryProvider extends ChangeNotifier implements CategoryProvider {
  static final _now = DateTime.now();

  @override
  List<Category> categories = [
    Category(id: 'cat-1', name: 'Food & Dining', type: CategoryType.expense, icon: 'restaurant', createdAt: _now, updatedAt: _now),
    Category(id: 'cat-2', name: 'Shopping', type: CategoryType.expense, icon: 'shopping_bag', createdAt: _now, updatedAt: _now),
    Category(id: 'cat-3', name: 'Split Pays', type: CategoryType.expense, icon: 'call_split', createdAt: _now, updatedAt: _now),
    Category(id: 'cat-4', name: 'Repays', type: CategoryType.expense, icon: 'handshake', createdAt: _now, updatedAt: _now),
    Category(id: 'cat-5', name: 'Invest.', type: CategoryType.expense, icon: 'trending_up', createdAt: _now, updatedAt: _now),
    Category(id: 'cat-6', name: 'Transp.', type: CategoryType.expense, icon: 'directions_car', createdAt: _now, updatedAt: _now),
    Category(id: 'cat-7', name: 'Family', type: CategoryType.expense, icon: 'family_restroom', createdAt: _now, updatedAt: _now),
    Category(id: 'cat-8', name: 'Salary', type: CategoryType.income, icon: 'payments', createdAt: _now, updatedAt: _now),
    Category(id: 'cat-9', name: 'Unique Extra Cat', type: CategoryType.expense, icon: 'local_hospital', createdAt: _now, updatedAt: _now),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  String get currencyCode => 'INR';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransactionProvider extends ChangeNotifier implements TransactionProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransferProvider extends ChangeNotifier implements TransferProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createTestWidget({Transaction? initialTransaction}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AccountProvider>(create: (_) => MockAccountProvider()),
      ChangeNotifierProvider<CategoryProvider>(create: (_) => MockCategoryProvider()),
      ChangeNotifierProvider<SettingsProvider>(create: (_) => MockSettingsProvider()),
      ChangeNotifierProvider<TransactionProvider>(create: (_) => MockTransactionProvider()),
      ChangeNotifierProvider<TransferProvider>(create: (_) => MockTransferProvider()),
    ],
    child: MaterialApp(
      home: AddEditTransactionScreen(
        initialTransaction: initialTransaction,
      ),
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AddEditTransactionScreen UI & State Tests', () {
    testWidgets('Amount input has transparent background, normal cursor, and thin underline', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find amount TextField
      final amountFieldFinder = find.byType(TextField).first;
      expect(amountFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(amountFieldFinder);
      expect(textField.decoration?.filled, isFalse);
      expect(textField.decoration?.fillColor, Colors.transparent);
      expect(textField.cursorWidth, 2.0);
      expect(textField.cursorHeight, 36.0);
      expect(textField.cursorColor, AppColors.primary);

      // Verify enter 0, 80, 1070.00, large numbers
      await tester.enterText(amountFieldFinder, '0');
      await tester.pump();
      expect(find.text('0'), findsWidgets);

      await tester.enterText(amountFieldFinder, '80');
      await tester.pump();
      expect(find.text('80'), findsOneWidget);

      await tester.enterText(amountFieldFinder, '1070.00');
      await tester.pump();
      expect(find.text('1070.00'), findsOneWidget);

      await tester.enterText(amountFieldFinder, '99999999.99');
      await tester.pump();
      expect(find.text('99999999.99'), findsOneWidget);
    });

    testWidgets('Category selection: tap selects item with clean border and checkmark, clears previous', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no checkmarks on categories
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Tap 'Food'
      final foodTile = find.text('Food');
      expect(foodTile, findsOneWidget);
      await tester.tap(foodTile);
      await tester.pumpAndSettle();

      // Exactly 1 checkmark appears on the selected Food category
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Tap 'Repays'
      final repaysTile = find.text('Repays');
      expect(repaysTile, findsOneWidget);
      await tester.tap(repaysTile);
      await tester.pumpAndSettle();

      // Exactly 1 checkmark remains, now moved to Repays
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Modifying amount and comment retains selected category
      final amountFieldFinder = find.byType(TextField).first;
      await tester.enterText(amountFieldFinder, '250.00');
      await tester.pump();

      final commentFieldFinder = find.byType(TextField).at(1);
      await tester.enterText(commentFieldFinder, 'Dinner with friends');
      await tester.pump();

      // Still selected!
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('Switching between Expenses and Income resets selection and displays correct mode categories', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select Food
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Switch to INCOME tab
      final incomeTab = find.text('INCOME');
      await tester.tap(incomeTab);
      await tester.pumpAndSettle();

      // Selection resets for income
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Switch back to EXPENSES
      final expensesTab = find.text('EXPENSES');
      await tester.tap(expensesTab);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('Editing existing transaction highlights its saved category even if not in default 6', (tester) async {
      final existingTx = Transaction(
        id: 'tx-extra',
        transactionType: CategoryType.expense,
        accountId: 'acc-1',
        categoryId: 'cat-9', // 'Unique Extra Cat'
        amount: Money.fromUnits(5000),
        date: DateTime.now(),
        description: 'Hospital visit',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(initialTransaction: existingTx));
      await tester.pumpAndSettle();

      // Saved amount pre-populated
      expect(find.text('50.00'), findsOneWidget);

      // 'Unique Extra Cat' is visible in grid and selected with checkmark
      expect(find.text('Unique Extra Cat'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
