import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> postSync({
    required String userId,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sync');
    final response = await _client.post(
      uri,
      headers: _headers(userId),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> getSync({
    required String userId,
    required String deviceId,
    required String cursor,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sync').replace(
      queryParameters: {
        'device_id': deviceId,
        'cursor': cursor,
      },
    );
    final response = await _client.get(uri, headers: _headers(userId));
    return _decode(response);
  }

  Future<Map<String, dynamic>> getHabits({required String userId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/habits');
    final response = await _client.get(uri, headers: _headers(userId));
    return _decode(response);
  }

  Future<Map<String, dynamic>> createHabit({
    required String userId,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/habits');
    final response = await _client.post(
      uri,
      headers: _headers(userId),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> updateHabit({
    required String userId,
    required String habitId,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/habits/$habitId');
    final response = await _client.patch(
      uri,
      headers: _headers(userId),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> deleteHabit({
    required String userId,
    required String habitId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/habits/$habitId');
    final response = await _client.delete(uri, headers: _headers(userId));
    return _decode(response);
  }

  Future<Map<String, dynamic>> completeHabit({
    required String userId,
    required String habitId,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/habits/$habitId/complete');
    final response = await _client.post(
      uri,
      headers: _headers(userId),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> getPet({required String userId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pet');
    final response = await _client.get(uri, headers: _headers(userId));
    return _decode(response);
  }

  Future<Map<String, dynamic>> getStats({required String userId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/stats');
    final response = await _client.get(uri, headers: _headers(userId));
    return _decode(response);
  }

  Future<Map<String, dynamic>> getStreaks({required String userId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/streaks');
    final response = await _client.get(uri, headers: _headers(userId));
    return _decode(response);
  }

  Map<String, String> _headers(String userId) {
    return {
      'Content-Type': 'application/json',
      'X-User-Id': userId,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
