import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const _kToken = 'origamit.auth.token';
  static const _kUserId = 'origamit.auth.user_id';
  static const _kEmail = 'origamit.auth.email';

  final FlutterSecureStorage _secure =
      const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  // In-memory snapshot used for synchronous reads from API client/headers.
  String? _token;
  String? _userId;
  String? _email;

  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  bool get isAuthenticated => _token != null && _userId != null;

  Future<void> load() async {
    if (kIsWeb) return; // secure storage on web is best-effort; skip silently
    _token = await _secure.read(key: _kToken);
    _userId = await _secure.read(key: _kUserId);
    _email = await _secure.read(key: _kEmail);
  }

  Future<void> save({
    required String token,
    required String userId,
    required String email,
  }) async {
    _token = token;
    _userId = userId;
    _email = email;
    if (kIsWeb) return;
    await _secure.write(key: _kToken, value: token);
    await _secure.write(key: _kUserId, value: userId);
    await _secure.write(key: _kEmail, value: email);
  }

  Future<void> clear() async {
    _token = null;
    _userId = null;
    _email = null;
    if (kIsWeb) return;
    await _secure.delete(key: _kToken);
    await _secure.delete(key: _kUserId);
    await _secure.delete(key: _kEmail);
  }
}
