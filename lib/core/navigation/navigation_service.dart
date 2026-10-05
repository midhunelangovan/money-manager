import 'package:flutter/material.dart';

class MainNavigationService {
  static final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();
  static ValueNotifier<int> currentTabNotifier = ValueNotifier<int>(0);

  static void openDrawer() {
    mainScaffoldKey.currentState?.openDrawer();
  }

  static void closeDrawer() {
    mainScaffoldKey.currentState?.closeDrawer();
  }

  static void navigateToTab(BuildContext context, int index) {
    currentTabNotifier.value = index;
    // If a modal or child page is on top of the shell, pop until we are back at the shell root
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
