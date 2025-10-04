import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kLoggedIn = 'logged_in';
  static const _kUsername = 'username';
  static const _kSynced = 'synced';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, value);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
  }

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsername, username);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUsername);
  }

  Future<void> setSynced(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSynced, v);
  }

  Future<bool> isSynced() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSynced) ?? false;
  }
}
