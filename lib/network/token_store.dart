import 'package:shared_preferences/shared_preferences.dart';

/// Persists the logged-in user's JWT pair. Mirrors the Android app's saveTokens / getJwtToken /
/// getRefreshToken / clearLoginData in AchoAppSharedPreferences.
class TokenStore {
  TokenStore._();

  static const String _jwtKey = 'jwt_token';
  static const String _refreshKey = 'refresh_token';

  static Future<String?> getJwt() async =>
      (await SharedPreferences.getInstance()).getString(_jwtKey);

  static Future<String?> getRefresh() async =>
      (await SharedPreferences.getInstance()).getString(_refreshKey);

  static Future<bool> isLoggedIn() async =>
      (await SharedPreferences.getInstance()).getBool('is_logged_in') ?? false;

  /// Saves a new access token and, when the server rotated it, the new refresh token.
  static Future<void> saveTokens(String jwt, String? refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jwtKey, jwt);
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString(_refreshKey, refresh);
    }
  }

  /// Forgets the session (tokens + logged-in flag + user identity), e.g. when the refresh token
  /// itself has expired and the user has to sign in again.
  static Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
    await prefs.remove(_refreshKey);
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('phone_number');
    await prefs.remove('role');
    await prefs.setBool('is_logged_in', false);
  }
}
