import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio HTTP simple para comunicarse con el backend.
///
/// - Configure el `baseUrl` al crear la instancia (ej. http://localhost:3000)
/// - Usa la clave `auth_token` en SharedPreferences para enviar Authorization Bearer.
class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Uri _uri(String path) => Uri.parse(baseUrl + path);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = _uri('/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw HttpException('Login failed', res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    final url = _uri('/auth/register');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw HttpException('Register failed', res.statusCode, res.body);
  }

  /// Register with optional clientChanges for migration.
  Future<Map<String, dynamic>> registerWithClientChanges(String username, String password, {List<Map<String, dynamic>>? clientChanges}) async {
    final url = _uri('/auth/register');
  final Map<String, dynamic> body = {'username': username, 'password': password};
    if (clientChanges != null) body['clientChanges'] = clientChanges;
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw HttpException('Register failed', res.statusCode, res.body);
  }

  Future<List<dynamic>> getTransactions() async {
    final url = _uri('/transactions');
    final headers = await _authHeaders();
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }

    throw HttpException('Failed to fetch transactions', res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> postTransaction(Map<String, dynamic> payload) async {
    final url = _uri('/transactions');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final res = await http.post(url, headers: headers, body: jsonEncode(payload));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw HttpException('Failed to create transaction', res.statusCode, res.body);
  }

  Future<List<dynamic>> getGoals() async {
    final url = _uri('/goals');
    final headers = await _authHeaders();
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }

    throw HttpException('Failed to fetch goals', res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> postGoal(Map<String, dynamic> payload) async {
    final url = _uri('/goals');
    final headers = await _authHeaders();
    // Debug: print payload that will be sent to the server
    // Use debugPrint to avoid analyzer 'avoid_print' suggestions
    debugPrint(payload.toString());
    headers['Content-Type'] = 'application/json';
    final res = await http.post(url, headers: headers, body: jsonEncode(payload));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw HttpException('Failed to create goal', res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> putGoal(String serverId, Map<String, dynamic> payload) async {
    final url = _uri('/goals/$serverId');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final res = await http.put(url, headers: headers, body: jsonEncode(payload));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw HttpException('Failed to update goal', res.statusCode, res.body);
  }

  Future<void> deleteGoal(String serverId) async {
    final url = _uri('/goals/$serverId');
    final headers = await _authHeaders();
    final res = await http.delete(url, headers: headers);

    if (res.statusCode == 204) return;

    throw HttpException('Failed to delete goal', res.statusCode, res.body);
  }

  Future<void> deleteTransaction(String serverId) async {
    final url = _uri('/transactions/$serverId');
    final headers = await _authHeaders();
    final res = await http.delete(url, headers: headers);

    if (res.statusCode == 204) return;

    throw HttpException('Failed to delete transaction', res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> postSync(Map<String, dynamic> payload) async {
    final url = _uri('/sync');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final res = await http.post(url, headers: headers, body: jsonEncode(payload));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw HttpException('Failed to sync', res.statusCode, res.body);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  HttpException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() => 'HttpException: $message (status: $statusCode) - $responseBody';
}
