import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/utilities/money.dart';
import 'package:kals_money_manager/core/widgets/app_splash_view.dart';
import 'package:kals_money_manager/core/widgets/confirm_dialog.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/settings/presentation/screens/personalization_settings_screen.dart';
import 'package:kals_money_manager/features/transactions/domain/entities/transaction.dart';
import 'package:kals_money_manager/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:provider/provider.dart';

class FakeSettingsProvider extends SettingsProvider {
  FakeSettingsProvider() : super(database: null);

  @override
  Future<void> loadSettings({bool force = false}) async {}
}

void main() {
  group('Kals Money Manager V2 – Fixed Branding & Safe Transaction Deletion Tests', () {
    testWidgets('1. Personalization settings screen has no app icon selection cards', (tester) async {
      final settings = FakeSettingsProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsProvider>.value(
            value: settings,
            child: const PersonalizationSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Profile and Home Dashboard are present
      expect(find.text('Personalization'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Home Dashboard'), findsOneWidget);

      // Verify no App Icon cards or Gemini/Wizard selection elements exist
      expect(find.text('App Icon'), findsNothing);
      expect(find.text('Wizard'), findsNothing);
      expect(find.text('Gemini'), findsNothing);
      expect(find.text('Choose your preferred home screen launcher icon'), findsNothing);
    });

    testWidgets('2. AppSplashView renders seamless startup container matching native splash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppSplashView(),
        ),
      );

      expect(find.byType(AppSplashView), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('3. TransactionListItem does not use Dismissible (prevents accidental deletion during vertical scroll)', (tester) async {
      final item = LedgerItem(
        id: 'tx_scroll_test',
        itemType: LedgerItemType.expense,
        amount: Money.fromUnits(150000), // 1500.00
        date: DateTime(2026, 11, 14, 10, 0),
        description: 'Office Electronics',
        accountId: 'acc_office',
        accountName: 'Business Account',
        createdAt: DateTime(2026, 11, 14, 10, 0),
      );

      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
              child: TransactionListItem(
                item: item,
                onTap: () {},
                onDelete: () => deleted = true,
              ),
            ),
          ),
        ),
      );

      // Horizontal dismiss gesture must NOT exist
      expect(find.byType(Dismissible), findsNothing);
      expect(deleted, isFalse);
    });

    testWidgets('4. TransactionListItem long press opens contextual menu with delete option and confirms before deletion', (tester) async {
      final item = LedgerItem(
        id: 'tx_contextual_1',
        itemType: LedgerItemType.expense,
        amount: Money.fromUnits(50000), // 500.00
        date: DateTime(2026, 11, 14, 11, 0),
        description: 'Team Lunch',
        accountId: 'acc_lunch',
        accountName: 'Primary Card',
        createdAt: DateTime(2026, 11, 14, 11, 0),
      );

      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
              child: TransactionListItem(
                item: item,
                onTap: () {},
                onDelete: () => deleted = true,
              ),
            ),
          ),
        ),
      );

      // Long press opens contextual bottom sheet
      await tester.longPress(find.text('Team Lunch'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('Delete Transaction'), findsOneWidget);

      // Tap Delete Transaction in menu -> prompts confirmation dialog
      await tester.tap(find.text('Delete Transaction'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDeleteConfirmationDialog), findsOneWidget);
      expect(find.text('Delete this transaction?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tapping Cancel dismisses without deleting
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
      expect(find.byType(TransactionDeleteConfirmationDialog), findsNothing);

      // Long press again and confirm deletion
      await tester.longPress(find.text('Team Lunch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Transaction'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
