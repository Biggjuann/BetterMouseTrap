import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _tokenKey = 'bm_auth_token';

  String? _token;
  SharedPreferences? _prefs;

  String? get token => _token;
  bool get isLoggedIn => _token != null;

  String get _baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    // On web: empty string = relative URLs (same origin as the page)
    // On mobile: Android emulator localhost alias
    return kIsWeb ? '' : 'http://10.0.2.2:8000';
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString(_tokenKey);
  }

  Future<bool> validateToken() async {
    if (_token == null) return false;
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> login(String email, String password) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
    );

    if (resp.statusCode != 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(body['detail'] ?? 'Login failed');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _token = data['access_token'] as String;
    await _prefs?.setString(_tokenKey, _token!);
    return _token!;
  }

  Future<String> register(String email, String password, String inviteCode) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'invite_code': inviteCode,
      }),
    );

    if (resp.statusCode != 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(body['detail'] ?? 'Registration failed');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _token = data['access_token'] as String;
    await _prefs?.setString(_tokenKey, _token!);
    return _token!;
  }

  Future<void> logout() async {
    _token = null;
    await _prefs?.remove(_tokenKey);
  }
}
