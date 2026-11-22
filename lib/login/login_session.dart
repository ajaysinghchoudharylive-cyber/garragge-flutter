import 'package:carsbuzz/home/main_shell.dart';
import 'package:carsbuzz/models/login_model.dart';
import 'package:carsbuzz/models/signup_user_model.dart';
import 'package:carsbuzz/network/api_client.dart';
import 'package:carsbuzz/network/firebase_service.dart';
import 'package:carsbuzz/network/token_store.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where to land after a successful login (Android: LOGIN_ORIGIN).
enum LoginOrigin { home, more, sell }

/// Backend login after Firebase verified the number. Mirrors the Android LoginRepo: POST
/// cars/login/signup {phone, firebaseToken}, then save the user + JWT pair.
class LoginSession {
  LoginSession._();

  /// Calls the backend and, on result "200", persists the session. Returns the response so the
  /// caller can decide where to go (e.g. Profile Details when the user has no name yet).
  /// Throws [LoginFailedException] with the server's message when the backend refuses the login.
  static Future<LoginModel> signUp(String phone10) async {
    final firebaseToken = await FirebaseService.getToken();
    final response = await ApiClient.create().sendOtp(
      SignUpUserModel(phone: phone10, firebaseToken: firebaseToken),
    );

    if (!response.isSuccess) {
      throw LoginFailedException(response.message);
    }
    // Every API call needs the JWT (same as Android); without it the user is not logged in.
    if (response.jwtToken.isEmpty) {
      throw LoginFailedException('Something went wrong!');
    }

    await TokenStore.saveTokens(response.jwtToken, response.refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('policies', response.policies);
    await prefs.setString('terms', response.terms);
    await prefs.setString('phone_number', phone10);

    final user = response.user;
    if (user != null) {
      if (user.id != null) await prefs.setString('user_id', user.id.toString());
      await prefs.setString('username', user.username ?? '');
      if (user.phone != null && user.phone!.isNotEmpty) {
        await prefs.setString('phone_number', user.phone!);
      }
      if (user.role != null) await prefs.setString('role', user.role!);
      if (user.state != null) await prefs.setString('state', user.state!);
      if (user.isPremium != null) await prefs.setBool('is_premium', user.isPremium!);
    }
    return response;
  }

  /// Clears the login screens and opens the app at the section the login started from.
  static void finish(BuildContext context, LoginOrigin origin) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainShell(
          initialTab: origin == LoginOrigin.more ? MainShell.tabMore : MainShell.tabDashboard,
          openSellOnStart: origin == LoginOrigin.sell,
        ),
      ),
      (route) => false,
    );
  }
}

class LoginFailedException implements Exception {
  final String message;
  LoginFailedException(this.message);

  @override
  String toString() => message;
}
