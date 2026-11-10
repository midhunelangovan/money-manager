import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/app_category_icon.dart';
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
      name: 'Cash Wallet',
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
  bool isLoading = false;

  @override
  Future<void> loadCategories({bool includeArchived = false}) async {}

  @override
  List<Category> categories = [
    // Expense Categories with distinctive custom colors
    Category(id: 'exp-1', name: 'Food & Dining', type: CategoryType.expense, icon: 'restaurant_rounded', color: 0xFFEA580C, createdAt: _now, updatedAt: _now),
    Category(id: 'exp-2', name: 'Groceries', type: CategoryType.expense, icon: 'shopping_basket_rounded', color: 0xFF059669, createdAt: _now, updatedAt: _now),
    Category(id: 'exp-3', name: 'Transportation', type: CategoryType.expense, icon: 'directions_car_rounded', color: 0xFF0284C7, createdAt: _now, updatedAt: _now),
    Category(id: 'exp-4', name: 'Housing & Rent', type: CategoryType.expense, icon: 'home_rounded', color: 0xFF7C3AED, createdAt: _now, updatedAt: _now),
    Category(id: 'exp-5', name: 'Bills & Utilities', type: CategoryType.expense, icon: 'receipt_long_rounded', color: 0xFFD97706, createdAt: _now, updatedAt: _now),
    Category(id: 'exp-6', name: 'Healthcare', type: CategoryType.expense, icon: 'medical_services_rounded', color: 0xFFE11D48, createdAt: _now, updatedAt: _now),
    Category(id: 'exp-7', name: 'Entertainment', type: CategoryType.expense, icon: 'movie_rounded', color: 0xFFDB2777, createdAt: _now, updatedAt: _now),

    // Income Categories with distinctive custom colors
    Category(id: 'inc-1', name: 'Salary', type: CategoryType.income, icon: 'payments_rounded', color: 0xFF059669, createdAt: _now, updatedAt: _now),
    Category(id: 'inc-2', name: 'Business / Freelance', type: CategoryType.income, icon: 'business_center_rounded', color: 0xFF0F766E, createdAt: _now, updatedAt: _now),
    Category(id: 'inc-3', name: 'Investment & Dividends', type: CategoryType.income, icon: 'trending_up_rounded', color: 0xFF2563EB, createdAt: _now, updatedAt: _now),
    Category(id: 'inc-4', name: 'Gifts / Grants', type: CategoryType.income, icon: 'card_giftcard_rounded', color: 0xFFDB2777, createdAt: _now, updatedAt: _now),
    Category(id: 'inc-5', name: 'Other Income', type: CategoryType.income, icon: 'savings_rounded', color: 0xFF475569, createdAt: _now, updatedAt: _now),
    Category(id: 'inc-6', name: 'Consulting Bonus', type: CategoryType.income, icon: 'badge_rounded', color: 0xFF7C3AED, createdAt: _now, updatedAt: _now),
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
  Transaction? lastCreatedTransaction;

  @override
  Future<void> createTransaction(Transaction transaction) async {
    lastCreatedTransaction = transaction;
  }

  @override
  Future<void> loadLedger() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransferProvider extends ChangeNotifier implements TransferProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createTestApp({
  Transaction? initialTransaction,
  EntryMode initialMode = EntryMode.expense,
  MockTransactionProvider? txProvider,
  MockCategoryProvider? catProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AccountProvider>(create: (_) => MockAccountProvider()),
      ChangeNotifierProvider<CategoryProvider>(create: (_) => catProvider ?? MockCategoryProvider()),
      ChangeNotifierProvider<SettingsProvider>(create: (_) => MockSettingsProvider()),
      ChangeNotifierProvider<TransactionProvider>(create: (_) => txProvider ?? MockTransactionProvider()),
      ChangeNotifierProvider<TransferProvider>(create: (_) => MockTransferProvider()),
    ],
    child: MaterialApp(
      home: AddEditTransactionScreen(
        initialTransaction: initialTransaction,
        initialMode: initialMode,
      ),
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Category Duplicate Selection & Original Colors Tests', () {
    testWidgets('1. Income: Selecting category A via More Categories highlights ONLY category A', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final txProvider = MockTransactionProvider();

      await tester.pumpWidget(createTestApp(
        initialMode: EntryMode.income,
        txProvider: txProvider,
      ));
      await tester.pumpAndSettle();

      // Ensure we are in Income mode
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Investment & Dividends'), findsOneWidget);

      // Initially no category is selected
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Tap 'More' to open CategoriesScreen in picker mode
      final moreTile = find.text('More');
      expect(moreTile, findsOneWidget);
      await tester.tap(moreTile);
      await tester.pumpAndSettle();

      // We should now be in CategoriesScreen (title: 'Select Category')
      expect(find.text('Select Category'), findsOneWidget);

      // Tap 'Investment & Dividends' (inc-3)
      final investmentCat = find.text('Investment & Dividends');
      expect(investmentCat, findsOneWidget);
      await tester.tap(investmentCat);
      await tester.pumpAndSettle();

      // Returned to AddEditTransactionScreen: exactly 1 checkmark is displayed!
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Verify that 'Investment & Dividends' is the ONLY category highlighted
      // Tap Category B: 'Salary' (inc-1) in main grid
      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();

      // Exactly 1 checkmark remains (Salary is now selected, Investment & Dividends unselected)
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Enter amount and save transaction
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '75000');
      await tester.pump();

      final saveButton = find.text('Add');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify Category B ('inc-1' Salary) was saved!
      expect(txProvider.lastCreatedTransaction, isNotNull);
      expect(txProvider.lastCreatedTransaction!.categoryId, 'inc-1');
      expect(txProvider.lastCreatedTransaction!.transactionType, CategoryType.income);
    });

    testWidgets('2. Expense: Selecting category via More Categories highlights ONLY that category', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final txProvider = MockTransactionProvider();

      await tester.pumpWidget(createTestApp(
        initialMode: EntryMode.expense,
        txProvider: txProvider,
      ));
      await tester.pumpAndSettle();

      // Tap 'More' to open CategoriesScreen
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Select Category'), findsOneWidget);

      // Select 'Healthcare' in More Categories
      await tester.tap(find.text('Healthcare'));
      await tester.pumpAndSettle();

      // Exactly 1 checkmark appears
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Select another category in the grid (e.g. 'Food')
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Still exactly 1 checkmark
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Enter amount and save
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '250.00');
      await tester.pump();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Food category ('exp-1') was saved
      expect(txProvider.lastCreatedTransaction, isNotNull);
      expect(txProvider.lastCreatedTransaction!.categoryId, 'exp-1');
      expect(txProvider.lastCreatedTransaction!.transactionType, CategoryType.expense);
    });

    testWidgets('3. Switch repeatedly between Income and Expense: no selection leakage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Select Food in Expense
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Switch to INCOME
      await tester.tap(find.text('INCOME'));
      await tester.pumpAndSettle();
      // Selection reset, no leakage
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Select Salary in Income
      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Switch to EXPENSES
      await tester.tap(find.text('EXPENSES'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Switch back to INCOME
      await tester.tap(find.text('INCOME'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('4. Original category icon colors are preserved in both screens (no global dark-green tint)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(initialMode: EntryMode.income));
      await tester.pumpAndSettle();

      // Find AppCategoryIcon widgets in main Income grid
      final categoryIcons = tester.widgetList<AppCategoryIcon>(find.byType(AppCategoryIcon)).toList();
      expect(categoryIcons.isNotEmpty, isTrue);

      // Verify configured colors are present on icons:
      // Salary: 0xFF059669 (Emerald)
      // Investment: 0xFF2563EB (Blue)
      // Gifts: 0xFFDB2777 (Pink)
      final iconColors = categoryIcons.map((i) => i.color).toList();
      expect(iconColors.contains(const Color(0xFF059669)), isTrue);
      expect(iconColors.contains(const Color(0xFF2563EB)), isTrue);
      expect(iconColors.contains(const Color(0xFFDB2777)), isTrue);

      // None of the actual category icons have the dark-green brand color 0xFF03323A
      for (final icon in categoryIcons) {
        if (icon.icon == Icons.payments_rounded) {
          expect(icon.color, const Color(0xFF059669));
        } else if (icon.icon == Icons.trending_up_rounded) {
          expect(icon.color, const Color(0xFF2563EB));
        }
      }

      // Open More Categories
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // In More Categories screen, icons also preserve their exact colors
      final moreScreenIcons = tester.widgetList<AppCategoryIcon>(find.byType(AppCategoryIcon)).toList();
      final moreColors = moreScreenIcons.map((i) => i.color).toList();
      expect(moreColors.contains(const Color(0xFF059669)), isTrue);
      expect(moreColors.contains(const Color(0xFF2563EB)), isTrue);
      expect(moreColors.contains(const Color(0xFFDB2777)), isTrue);
      expect(moreColors.contains(const Color(0xFF7C3AED)), isTrue);
    });

    testWidgets('5. Reopening More Categories initializes visual selection state from actual selected category', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(initialMode: EntryMode.income));
      await tester.pumpAndSettle();

      // Select Salary in main grid
      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Open More Categories
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Inside More Categories, Salary is ALREADY visually selected!
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Select Consulting Bonus (inc-6)
      await tester.tap(find.text('Consulting Bonus'));
      await tester.pumpAndSettle();

      // Back on main screen: Consulting Bonus is swapped in and selected!
      expect(find.text('Consulting Bonus'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Reopen More Categories again
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Consulting Bonus is visually selected!
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
