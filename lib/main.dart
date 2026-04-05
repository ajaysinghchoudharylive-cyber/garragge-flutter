
import 'package:carsbuzz/auth/auth_wrapper.dart';
import 'package:carsbuzz/network/firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔥 Try to initialize Firebase
    await Firebase.initializeApp(demoProjectId: 'carsbuzz-a724f');
    await FirebaseService.init();
    debugPrint('🔥 Firebase initialized successfully');
  } catch (e) {
    // If Firebase initialization fails, continue without it
    debugPrint('🔥 Firebase initialization failed: $e');
    debugPrint('🔥 Continuing in test mode...');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Apply Roboto font to the entire app
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        // Apply Roboto to AppBar text
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Apply Roboto to ElevatedButton text
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Apply Roboto to TextButton text
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      home: const AuthWrapper(), // ✅ Now checks auth status first
    );
  }
}
