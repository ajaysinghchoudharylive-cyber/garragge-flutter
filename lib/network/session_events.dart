import 'package:flutter/widgets.dart';

/// Lets the networking layer send the user back to the login screen when their session is dead
/// (refresh token expired or revoked), without the network code knowing about any screens.
///
/// `main.dart` registers [navigatorKey] on the MaterialApp and sets [onSessionExpired].
class SessionEvents {
  SessionEvents._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Called once per expiry after the stored session has been cleared.
  static VoidCallback? onSessionExpired;

  static bool _notifying = false;

  static void notifyExpired() {
    if (_notifying) return; // several in-flight requests can fail together
    _notifying = true;
    try {
      onSessionExpired?.call();
    } finally {
      Future.delayed(const Duration(seconds: 2), () => _notifying = false);
    }
  }
}
