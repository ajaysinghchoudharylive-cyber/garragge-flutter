import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks the user to turn notifications back on when they are off (permission denied, or switched
/// off in system settings). Mirrors the native Android app's prompt on the car screens.
///
/// - Shown at most once every [_interval], so it never nags.
/// - If the system permission dialog can no longer appear (user chose "Don't allow" before), the
///   user is sent to the app's settings page instead.
class NotificationPermissionPrompt {
  NotificationPermissionPrompt._();

  static const String _lastShownKey = 'notification_prompt_last_shown_millis';
  static const Duration _interval = Duration(days: 3);

  /// A system permission dialog needs a human to read and tap it, which takes far longer than this.
  /// If the request returns faster and notifications are still off, no dialog was shown.
  static const Duration _dialogNotShownThreshold = Duration(milliseconds: 700);

  static bool _showing = false;

  static bool _isOn(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  /// Call from a screen once its content has loaded. Does nothing when notifications are already
  /// on, or when the prompt was shown within the last few days.
  static Future<void> maybeAsk(BuildContext context) async {
    if (_showing) return;

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (_isOn(settings.authorizationStatus)) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = prefs.getInt(_lastShownKey) ?? 0;
    if (now - last < _interval.inMilliseconds) return;
    if (!context.mounted) return;

    _showing = true;
    await prefs.setInt(_lastShownKey, now);
    try {
      await showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => _PromptSheet(
          onEnable: () => _enable(context, sheetContext),
        ),
      );
    } finally {
      _showing = false;
    }
  }

  static Future<void> _enable(
      BuildContext screenContext, BuildContext sheetContext) async {
    final started = DateTime.now();
    final settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    final elapsed = DateTime.now().difference(started);

    if (sheetContext.mounted) Navigator.pop(sheetContext);

    final turnedOn = _isOn(settings.authorizationStatus);
    if (!turnedOn && elapsed < _dialogNotShownThreshold) {
      // No system dialog appeared: the permission is blocked, so Settings is the only way.
      if (screenContext.mounted) await _showSettingsDialog(screenContext);
    }
  }

  static Future<void> _showSettingsDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Turn on notifications'),
        content: const Text(
          'Notifications are turned off for Garragge.com. Turn them on in settings to get '
          'deals, price drops and updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Geolocator.openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}

class _PromptSheet extends StatelessWidget {
  final Future<void> Function() onEnable;

  const _PromptSheet({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_active_outlined,
                size: 48, color: Color(0xFF1A73E8)),
            const SizedBox(height: 16),
            const Text(
              'GET IMPORTANT UPDATES',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the very first to know. Enable notifications to stay updated on deals, '
              'drops and deliveries.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onEnable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('ENABLE NOTIFICATIONS'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}
