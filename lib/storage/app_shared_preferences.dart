
import 'package:shared_preferences/shared_preferences.dart';

class AppSharedPreferences {
  final SharedPreferences prefs;

  AppSharedPreferences(this.prefs);

  Future<void> saveUserId(String id) async =>
      prefs.setString('user_id', id);

  Future<void> saveUsername(String username) async =>
      prefs.setString('username', username);

  Future<void> setPolicies(String policies) async =>
      prefs.setString('policies', policies);

  Future<void> setTerms(String terms) async =>
      prefs.setString('terms', terms);

  Future<void> setIsLoggedIn(bool value) async =>
      prefs.setBool('is_logged_in', value);

  Future<void> saveDealerCity(String? city) async =>
      prefs.setString('city', city ?? '');

  Future<void> saveDealerState(String? state) async =>
      prefs.setString('state', state ?? '');

  Future<void> savePremium(bool? value) async =>
      prefs.setBool('is_premium', value ?? false);
}
