import 'dart:async';
import 'package:flutter/material.dart';
import '../navigation/navigation_service.dart';
import '../theme/app_colors.dart';

/// Centralized utility for presenting clean, consistent, non-intrusive SnackBars.
///
/// Ensures ordinary success messages automatically dismiss after ~2-3 seconds,
/// actions with Undo remain available for ~5 seconds then cleanly auto-dismiss,
/// clears prior stacked/queued messages to prevent duplicate annoyance, and does
/// not require manual scroll/swipe gestures to dismiss.
class AppSnackBar {
  /// Default duration for ordinary success and information notifications (~2.5 seconds).
  static const Duration defaultSuccessDuration = Duration(milliseconds: 2500);

  /// Standard defined window for Undo actions (5 seconds).
  static const Duration defaultUndoDuration = Duration(milliseconds: 5000);

  /// Extended duration for error notifications where the user needs time to read.
  static const Duration defaultErrorDuration = Duration(milliseconds: 4000);

  /// Generation token tracking active notifications to invalidate old timers immediately.
  static int _generationToken = 0;

  /// Active dismiss timer for undo actions.
  static Timer? _activeTimer;

  /// Helper to get the active ScaffoldMessengerState.
  static ScaffoldMessengerState? _resolveMessenger(BuildContext? context) {
    if (context != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) return messenger;
    }
    final rootContext = MainNavigationService.navigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      return ScaffoldMessenger.maybeOf(rootContext);
    }
    return null;
  }

  /// Clears any active SnackBars immediately to prevent overlapping or duplicate messages.
  static void clear([BuildContext? context]) {
    _activeTimer?.cancel();
    _activeTimer = null;
    _resolveMessenger(context)?.clearSnackBars();
  }

  /// Shows an ordinary success message that automatically dismisses after ~2.5 seconds.
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = defaultSuccessDuration,
  }) {
    final messenger = _resolveMessenger(context);
    if (messenger == null) return;

    _generationToken++;
    _activeTimer?.cancel();
    _activeTimer = null;

    // Immediately dismiss any previous snackbar to avoid stacking
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
  }

  /// Shows an action with a guaranteed 5-second Undo action window.
  ///
  /// - Automatically dismisses after 5 seconds.
  /// - Tapping Undo reverses the operation safely and cannot be triggered twice.
  /// - If a new transaction or notification arrives, prior Undo callbacks are invalidated immediately.
  /// - Non-blocking floating layout allows background interaction.
  static void showSuccessWithUndo(
    BuildContext context, {
    required String message,
    required Future<void> Function() onUndo,
    Duration duration = defaultUndoDuration,
    VoidCallback? onDismissed,
  }) {
    final messenger = _resolveMessenger(context);
    if (messenger == null) return;

    _generationToken++;
    final thisToken = _generationToken;
    _activeTimer?.cancel();
    _activeTimer = null;
    bool hasUndone = false;

    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.amber,
          onPressed: () async {
            if (hasUndone || thisToken != _generationToken) return;
            hasUndone = true;
            _activeTimer?.cancel();
            _activeTimer = null;
            messenger.hideCurrentSnackBar();
            try {
              await onUndo();
            } catch (e) {
              final rootCtx = MainNavigationService.navigatorKey.currentContext ?? context;
              if (rootCtx.mounted) {
                showError(rootCtx, 'Failed to undo: $e');
              }
            }
          },
        ),
      ),
    );

    // Guaranteed auto-dismissal after the 5-second window expires,
    // overcoming Flutter/OEM accessibility services keeping interactive SnackBars persistent.
    _activeTimer = Timer(duration, () {
      if (thisToken == _generationToken && !hasUndone) {
        messenger.hideCurrentSnackBar();
      }
      _activeTimer = null;
    });

    controller.closed.then((reason) {
      if (thisToken == _generationToken) {
        _activeTimer?.cancel();
        _activeTimer = null;
        if (!hasUndone) {
          onDismissed?.call();
        }
      }
    });
  }

  /// Shows an error message. Errors stay visible until dismissed or for ~4 seconds.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = defaultErrorDuration,
    SnackBarAction? action,
  }) {
    final messenger = _resolveMessenger(context);
    if (messenger == null) return;

    _generationToken++;
    _activeTimer?.cancel();
    _activeTimer = null;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.expense,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
  }

  /// Shows an informational or progress message (auto-dismiss after ~2.5 seconds).
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = defaultSuccessDuration,
    SnackBarAction? action,
  }) {
    final messenger = _resolveMessenger(context);
    if (messenger == null) return;

    _generationToken++;
    _activeTimer?.cancel();
    _activeTimer = null;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
  }
}
