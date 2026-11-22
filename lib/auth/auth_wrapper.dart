import 'package:carsbuzz/home/main_shell.dart';
import 'package:flutter/material.dart';

/// App entry. Like the Android MainActivity, everyone (guest or logged in) lands on the home
/// screen; login is asked for only when needed (Sell, or "Login to continue" on the More tab).
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) => const MainShell();
}
