import 'package:flutter/material.dart';

/// Lightweight, sensitive-data-free diagnostic logger for navigation & lifecycle events.
class AppLogger {
  static void log(String tag, String message) {
    final now = DateTime.now().toIso8601String();
    debugPrint('[$now][$tag] $message');
  }

  static void info(String tag, String message) => log(tag, 'INFO: $message');
  static void warn(String tag, String message) => log(tag, 'WARN: $message');
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final now = DateTime.now().toIso8601String();
    debugPrint('[$now][$tag] ERROR: $message ${error != null ? '($error)' : ''}');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}

/// NavigatorObserver that safely logs navigation routing and ensures transparency.
class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppLogger.log(
      'KALS_TXN_NAV',
      'Pushed route: ${route.settings.name ?? route.runtimeType} (previous: ${previousRoute?.settings.name ?? previousRoute?.runtimeType})',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppLogger.log(
      'KALS_TXN_NAV',
      'Popped route: ${route.settings.name ?? route.runtimeType} (returned to: ${previousRoute?.settings.name ?? previousRoute?.runtimeType})',
    );
    if (previousRoute == null) {
      AppLogger.log('KALS_TXN_NAV', 'WARNING: Route was popped leaving 0 routes in the Navigator!');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    AppLogger.log(
      'KALS_TXN_NAV',
      'Replaced route: ${oldRoute?.settings.name ?? oldRoute?.runtimeType} with ${newRoute?.settings.name ?? newRoute?.runtimeType}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    AppLogger.log(
      'KALS_TXN_NAV',
      'Removed route: ${route.settings.name ?? route.runtimeType}',
    );
  }
}

