import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import '../navigation/navigation_service.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.kals.kals_money_manager.dev/widget_channel');
  static bool _isInitialized = false;
  static bool isTestMode = false;

  static void initialize() {
    if (_isInitialized || isTestMode) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final action = call.arguments as String?;
        if (action != null) {
          handleWidgetAction(action);
        }
      }
    });

    // Check for initial action on cold start
    _checkInitialAction();
  }

  static Future<void> _checkInitialAction() async {
    if (isTestMode) return;
    try {
      final initialAction = await _channel.invokeMethod<String>('getInitialAction');
      if (initialAction != null) {
        // Allow widget tree to settle before pushing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleWidgetAction(initialAction);
        });
      }
    } catch (_) {}
  }

  static void handleWidgetAction(String action) {
    if (isTestMode) return;
    final context = MainNavigationService.navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final mode = (action.toLowerCase() == 'income') ? EntryMode.income : EntryMode.expense;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          initialMode: mode,
        ),
      ),
    );
  }
}
