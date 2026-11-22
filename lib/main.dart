import 'package:carsbuzz/auth/auth_wrapper.dart';
import 'package:carsbuzz/network/firebase_service.dart';
import 'package:carsbuzz/network/session_events.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Uses the real project config from google-services.json / GoogleService-Info.plist.
    // (The old `demoProjectId` argument created a fake emulator-only app, so phone login and
    // push notifications could never work against the real Firebase project.)
    await Firebase.initializeApp();
    await FirebaseService.init();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // When the refresh token is refused the stored session has already been cleared; restart at
  // the home screen as a guest (same as Android, which drops back to the logged-out state).
  SessionEvents.onSessionExpired = () {
    final navigator = SessionEvents.navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SessionEvents.navigatorKey,
      title: 'Garragge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Outfit is the Android app's font (res/font/outfit_*.ttf).
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
