import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kLoggedIn = 'logged_in';
  static const _kUsername = 'username';
  static const _kSynced = 'synced';
  static const _kAuthToken = 'auth_token';

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

  /// Save auth token (e.g. JWT) locally
  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAuthToken, token);
  }

  /// Get saved auth token or null
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAuthToken);
  }

  /// Clear saved auth token
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuthToken);
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
