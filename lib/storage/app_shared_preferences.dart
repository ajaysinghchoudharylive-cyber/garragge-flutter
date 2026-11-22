
import 'package:shared_preferences/shared_preferences.dart';

class AppSharedPreferences {
  final SharedPreferences prefs;

  AppSharedPreferences(this.prefs);

  // Setters
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

  Future<void> saveSelectedLocation(String address, String? title) async {
    await prefs.setString('selected_address', address);
    if (title != null) {
      await prefs.setString('selected_address_title', title);
    }
  }

  // Getters
  String? getUserId() => prefs.getString('user_id');
  String? getUsername() => prefs.getString('username');
  String? getPolicies() => prefs.getString('policies');
  String? getTerms() => prefs.getString('terms');
  bool getIsLoggedIn() => prefs.getBool('is_logged_in') ?? false;
  String? getDealerCity() => prefs.getString('city');
  String? getDealerState() => prefs.getString('state');
  bool getIsPremium() => prefs.getBool('is_premium') ?? false;
  String? getSelectedAddress() => prefs.getString('selected_address');
  String? getSelectedAddressTitle() => prefs.getString('selected_address_title');

  // Logout - Clear all user data
  Future<void> logout() async {
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('city');
    await prefs.remove('state');
    await prefs.remove('is_premium');
    await prefs.remove('selected_address');
    await prefs.remove('selected_address_title');
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    await prefs.remove('phone_number');
    await prefs.remove('role');
    await prefs.setBool('is_logged_in', false);
    // Keep policies and terms as they're not user-specific
  }
}
