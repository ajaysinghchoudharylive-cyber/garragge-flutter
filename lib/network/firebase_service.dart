import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  /// Call this ONCE when app starts
  static Future<void> init() async {
    if (Platform.isIOS) {
      await _requestIOSPermission();
    }
  }

  static Future<void> _requestIOSPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Always returns latest FCM token
  static Future<String> getToken() async {
    try {
      final token = await _messaging.getToken();
      // ignore: avoid_print
      print("🔥 FCM TOKEN: $token");
      return token ?? "";
    } catch (e) {
      return "";
    }
  }
}
