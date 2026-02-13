import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _tokenKey = 'bm_auth_token';
  static const _onboardingKey = 'bm_onboarding_seen';

  String? _token;
  SharedPreferences? _prefs;
  bool _onboardingSeen = false;

  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get onboardingSeen => _onboardingSeen;

  String get _baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    // On web: use the same origin the page was loaded from
    // On mobile: Android emulator localhost alias
    return kIsWeb ? Uri.base.origin : 'http://10.0.2.2:8000';
  }

  /// Whether Sign in with Apple is available on this platform.
  bool get isAppleSignInAvailable => !kIsWeb && Platform.isIOS;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString(_tokenKey);
    _onboardingSeen = _prefs?.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    _onboardingSeen = true;
    await _prefs?.setBool(_onboardingKey, true);
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

  Future<String> register(String email, String password, [String? inviteCode]) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (inviteCode != null && inviteCode.isNotEmpty) {
      body['invite_code'] = inviteCode;
    }

    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Registration failed');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _token = data['access_token'] as String;
    await _prefs?.setString(_tokenKey, _token!);
    return _token!;
  }

  Future<String> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw Exception('Apple Sign-In failed: no identity token received');
    }

    // Build full name if provided (Apple only sends name on first sign-in)
    String? fullName;
    if (credential.givenName != null || credential.familyName != null) {
      fullName = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      if (fullName.isEmpty) fullName = null;
    }

    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/apple'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identity_token': identityToken,
        'email': credential.email,
        'full_name': fullName,
      }),
    );

    if (resp.statusCode != 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Apple Sign-In failed');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _token = data['access_token'] as String;
    await _prefs?.setString(_tokenKey, _token!);
    return _token!;
  }

  /// Step 1: Request a password reset code.
  Future<void> forgotPassword(String email) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (resp.statusCode == 429) {
      throw Exception('Too many requests. Please wait a moment.');
    }

    if (resp.statusCode != 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Failed to send reset code');
    }
  }

  /// Step 2: Verify the 6-digit code, returns a reset token.
  Future<String> verifyResetCode(String email, String code) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (resp.statusCode == 429) {
      throw Exception('Too many attempts. Please wait a moment.');
    }

    if (resp.statusCode != 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Invalid code');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['reset_token'] as String;
  }

  /// Step 3: Reset password using the reset token.
  Future<void> resetPassword(String resetToken, String newPassword) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reset_token': resetToken,
        'new_password': newPassword,
      }),
    );

    if (resp.statusCode != 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Failed to reset password');
    }
  }

  Future<void> logout() async {
    _token = null;
    await _prefs?.remove(_tokenKey);
  }
}
