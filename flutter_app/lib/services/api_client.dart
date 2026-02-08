import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/api_responses.dart';
import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_hit.dart';
import '../models/product_input.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the server returns 401 — the UI layer should redirect to login.
class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  /// Called by the UI when a [UnauthorizedException] is caught.
  void Function()? onUnauthorized;

  String get _baseUrl {
    const configured =
        String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;
    // On web: empty string = relative URLs (same origin as the page)
    // On mobile: Android emulator localhost alias
    return kIsWeb ? '' : 'http://10.0.2.2:8000';
  }

  Future<List<IdeaVariant>> generateIdeas({
    required String text,
    String? category,
    bool random = false,
  }) async {
    final body = <String, dynamic>{
      'text': text,
      'random': random,
    };
    if (category != null) body['category'] = category;

    final data = await _post('/ideas/generate', body);
    return GenerateIdeasResponse.fromJson(data).variants;
  }

  Future<IdeaSpec> generateSpec({
    required String productText,
    required IdeaVariant variant,
  }) async {
    final body = {
      'product_text': productText,
      'variant_id': variant.id,
      'variant': variant.toJson(),
    };
    final data = await _post('/ideas/spec', body);
    return GenerateSpecResponse.fromJson(data).spec;
  }

  Future<PatentSearchResponse> searchPatents({
    required List<String> queries,
    required List<String> keywords,
    int limit = 10,
  }) async {
    final body = {
      'queries': queries,
      'keywords': keywords,
      'limit': limit,
    };
    final data = await _post('/patents/search', body);
    return PatentSearchResponse.fromJson(data);
  }

  Future<ExportResponse> exportOnePager({
    required ProductInput product,
    required IdeaVariant variant,
    required IdeaSpec spec,
    required List<PatentHit> hits,
  }) async {
    final body = {
      'product': product.toJson(),
      'variant': variant.toJson(),
      'spec': spec.toJson(),
      'hits': hits.map((h) => h.toJson()).toList(),
    };
    final data = await _post('/export/onepager', body);
    return ExportResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    final token = AuthService.instance.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      response = await http.post(uri, headers: headers, body: jsonEncode(body));
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    if (response.statusCode == 401) {
      await AuthService.instance.logout();
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Server error (${response.statusCode}): ${response.body}',
      );
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to parse response: $e');
    }
  }
}
