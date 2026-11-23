import 'package:flutter/material.dart';
import '../utilities/app_logger.dart';

class MainNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();
  static final ValueNotifier<int> currentTabNotifier = ValueNotifier<int>(0);

  /// Root shell does not ping-pong through tab history; system back exits/backgrounds app.
  static bool get canPopTab => false;
  static int get currentTab => currentTabNotifier.value;

  static void openDrawer() {
    mainScaffoldKey.currentState?.openDrawer();
  }

  static void closeDrawer() {
    mainScaffoldKey.currentState?.closeDrawer();
  }

  static void pushTab(int index) {
    if (index != currentTabNotifier.value) {
      AppLogger.info('Navigation', 'Switched root tab to index $index');
      currentTabNotifier.value = index;
    }
  }

  static void navigateToTab(BuildContext context, int index) {
    // If a modal or child page is on top of the shell, pop until we are back at the shell root
    final nav = navigatorKey.currentState ?? Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    pushTab(index);
  }

  /// Navigates to a top-level non-root drawer destination.
  /// Enforces the requirement that Home (Dashboard, Tab 0) is the logical landing
  /// destination when the top-level drawer destination is exited.
  static Future<T?> openDrawerDestination<T>(
    BuildContext context,
    Widget screen,
  ) {
    // 1. Close drawer if open
    if (mainScaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    // 2. Unwind any existing modal/child pages on top of the shell
    final nav = navigatorKey.currentState ?? Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    // 3. Set the underlying root tab to Home (Dashboard, index 0)
    pushTab(0);
    // 4. Push the drawer destination route
    return nav.push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static bool popTab() {
    // Root level tabs do not ping-pong
    return false;
  }

  static void resetTabHistory([int initialTab = 0]) {
    currentTabNotifier.value = initialTab;
  }
}
