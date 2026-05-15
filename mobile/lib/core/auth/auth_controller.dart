import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_session.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final bool isBusy;
  final String? error;

  const AuthState({
    required this.status,
    this.userId,
    this.email,
    this.isBusy = false,
    this.error,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState.unknown()) {
    _bootstrap();
  }

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> _bootstrap() async {
    await AuthSession.instance.load();
    if (AuthSession.instance.isAuthenticated) {
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: AuthSession.instance.userId,
        email: AuthSession.instance.email,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.login(email: email, password: password);
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: AuthSession.instance.userId,
        email: AuthSession.instance.email,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> register(
      {required String email, required String password}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.register(email: email, password: password);
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: AuthSession.instance.userId,
        email: AuthSession.instance.email,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
