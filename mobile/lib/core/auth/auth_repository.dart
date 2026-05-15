import 'dart:convert';

import 'package:http/http.dart' as http;

import '../network/api_client.dart';
import '../network/api_config.dart';
import 'auth_session.dart';

class AuthRepository {
  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/register', email, password);
    await _persist(response);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', email, password);
    await _persist(response);
  }

  Future<void> logout() async {
    await AuthSession.instance.clear();
  }

  Future<Map<String, dynamic>> _post(
      String path, String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractError(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _persist(Map<String, dynamic> body) async {
    final token = body['token'] as String?;
    final userId = body['user_id'] as String?;
    final email = body['email'] as String? ?? '';
    if (token == null || userId == null) {
      throw ApiException('Malformed auth response');
    }
    await AuthSession.instance.save(
      token: token,
      userId: userId,
      email: email,
    );
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final message = decoded['error'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }
}
