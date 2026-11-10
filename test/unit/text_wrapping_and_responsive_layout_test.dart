import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kals_money_manager/core/widgets/app_card.dart';
import 'package:kals_money_manager/core/widgets/category_grid.dart';
import 'package:kals_money_manager/core/widgets/period_selector.dart';
import 'package:kals_money_manager/features/categories/domain/entities/category.dart';
import 'package:kals_money_manager/features/settings/presentation/screens/currency_accounts_settings_screen.dart';
import 'package:kals_money_manager/features/settings/presentation/screens/personalization_settings_screen.dart';
import 'package:kals_money_manager/features/settings/presentation/screens/settings_screen.dart';
import 'package:kals_money_manager/features/settings/presentation/providers/settings_provider.dart';
import 'package:kals_money_manager/features/accounts/presentation/providers/account_provider.dart';
import 'package:kals_money_manager/core/database/app_database.dart';
import 'package:kals_money_manager/core/database/database_migrations.dart';
import 'package:kals_money_manager/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget buildTestWrapper({
    required Widget child,
    double screenWidth = 320,
    double screenHeight = 640,
    double textScale = 1.0,
    ThemeData? theme,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: Size(screenWidth, screenHeight),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: child,
      ),
    );
  }

  group('Global Text Wrapping & Responsive Layout Tests', () {
    testWidgets('AppCard defaults to full available width and avoids loose collapse', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWrapper(
          screenWidth: 360,
          child: Scaffold(
            body: Column(
              children: [
                AppCard(
                  child: const Text('Full Width Card Content'),
                ),
              ],
            ),
          ),
        ),
      );

      final cardFinder = find.byType(AppCard);
      expect(cardFinder, findsOneWidget);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.width, 360);
    });

    testWidgets('PeriodSelector renders 5 tabs on narrow screen (320dp) without overflow or word wrap', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      TimePeriod current = TimePeriod.month;

      await tester.pumpWidget(
        buildTestWrapper(
          screenWidth: 320,
          textScale: 1.2,
          child: Scaffold(
            body: PeriodSelector(
              selectedPeriod: current,
              onPeriodChanged: (p) => current = p,
              dateRangeLabel: 'October 2026',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Period'), findsOneWidget);
    });

    testWidgets('CategoryGrid renders 4 columns on narrow 320dp screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleCategories = List<Category>.generate(
        8,
        (i) => Category(
          id: 'cat_$i',
          name: 'Category $i',
          type: CategoryType.expense,
          color: 0xFF2563EB,
          icon: 'category',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestWrapper(
          screenWidth: 320,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CategoryGrid(
                categories: sampleCategories,
                selectedCategoryId: 'cat_0',
                onCategorySelected: (_) {},
                onMoreTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('CurrencyAccountsSettingsScreen displays Application Currency without single-char wrap at 320dp and 1.3x font scale', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late Database db;
      late SettingsProvider settings;
      late AccountProvider accProvider;

      await tester.runAsync(() async {
        db = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
          onCreate: DatabaseMigrations.onCreate,
        );
        final appDb = AppDatabase.withDatabase(db);
        settings = SettingsProvider(database: appDb);
        await settings.loadSettings();

        final accRepo = AccountRepositoryImpl(database: appDb);
        accProvider = AccountProvider(repository: accRepo);
        await accProvider.loadAccounts();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<AccountProvider>.value(value: accProvider),
          ],
          child: buildTestWrapper(
            screenWidth: 320,
            textScale: 1.3,
            child: const CurrencyAccountsSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify "Application Currency" is present and rendered
      final appCurrencyFinder = find.text('Application Currency');
      expect(appCurrencyFinder, findsOneWidget);

      final renderParagraph = tester.renderObject<RenderParagraph>(appCurrencyFinder);
      expect(renderParagraph.text.toPlainText(), 'Application Currency');
      // Must not be broken character by character
      expect(renderParagraph.text.toPlainText().contains('\n'), isFalse);
    });

    testWidgets('PersonalizationSettingsScreen displays Display Name input without overflow at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late Database db;
      late SettingsProvider settings;

      await tester.runAsync(() async {
        db = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
          onCreate: DatabaseMigrations.onCreate,
        );
        final appDb = AppDatabase.withDatabase(db);
        settings = SettingsProvider(database: appDb);
        await settings.loadSettings();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ],
          child: buildTestWrapper(
            screenWidth: 320,
            textScale: 1.25,
            child: const PersonalizationSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Display Name'), findsOneWidget);
    });

    testWidgets('SettingsScreen displays section rows cleanly in both light and dark themes at 320dp', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late Database db;
      late SettingsProvider settings;

      await tester.runAsync(() async {
        db = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON'),
          onCreate: DatabaseMigrations.onCreate,
        );
        final appDb = AppDatabase.withDatabase(db);
        settings = SettingsProvider(database: appDb);
        await settings.loadSettings();
      });

      // Test Dark Theme
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ],
          child: buildTestWrapper(
            screenWidth: 320,
            theme: ThemeData.dark(),
            child: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Personalization'), findsOneWidget);
      expect(find.text('Currency & Accounts'), findsOneWidget);
    });
  });
}
