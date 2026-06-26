import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import 'auth_storage.dart';

enum AuthStatus { unknown, signedOut, signingIn, signedIn, error }

class AuthState {
  const AuthState({
    required this.status,
    this.userName,
    this.userEmail,
    this.error,
  });

  final AuthStatus status;
  final String? userName;
  final String? userEmail;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    String? userName,
    String? userEmail,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        userName: userName ?? this.userName,
        userEmail: userEmail ?? this.userEmail,
        error: error,
      );

  static const initial = AuthState(status: AuthStatus.unknown);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._storage, this._api) : super(AuthState.initial) {
    _bootstrap();
  }

  final AuthStorage _storage;
  final ApiClient _api;

  Future<void> _bootstrap() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.signedOut);
      return;
    }
    final profile = await _storage.readProfile();
    state = state.copyWith(
      status: AuthStatus.signedIn,
      userName: profile['name'],
      userEmail: profile['email'],
    );
  }

  /// Dev-only: create a local-only "preview" session so the UI is browsable
  /// without hitting any auth server. Tokens are throwaway placeholders.
  Future<void> signInAsDev() async {
    state = state.copyWith(status: AuthStatus.signingIn, error: null);
    await _storage.writeSession(
      accessToken: 'dev-bypass-access-token',
      refreshToken: 'dev-bypass-refresh-token',
      userId: '00000000-0000-0000-0000-000000000000',
      email: 'preview@twende.local',
      fullName: 'Preview Traveler',
      role: 'traveler',
    );
    state = const AuthState(
      status: AuthStatus.signedIn,
      userName: 'Preview Traveler',
      userEmail: 'preview@twende.local',
    );
  }

  Future<void> signInWithBaseIdP() async {
    state = state.copyWith(status: AuthStatus.signingIn, error: null);
    try {
      final verifier = _generateVerifier();
      final challenge = _challenge(verifier);
      final stateParam = _randomString(24);

      final authorizeUrl = Uri.parse(
        '${ApiConfig.idpIssuer}/oauth2/authorize',
      ).replace(queryParameters: {
        'response_type': 'code',
        'client_id': ApiConfig.idpClientId,
        'redirect_uri': ApiConfig.mobileRedirectUri,
        'scope': 'openid profile',
        'state': stateParam,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      }).toString();

      final result = await FlutterWebAuth2.authenticate(
        url: authorizeUrl,
        callbackUrlScheme: ApiConfig.mobileRedirectScheme,
      );

      final returned = Uri.parse(result);
      final code = returned.queryParameters['code'];
      final returnedState = returned.queryParameters['state'];

      if (returnedState != stateParam) {
        throw Exception('State mismatch — possible CSRF');
      }
      if (code == null || code.isEmpty) {
        throw Exception('Authorization code missing');
      }

      final resp = await _api.dio.post('/auth/idp-exchange', data: {
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': ApiConfig.mobileRedirectUri,
      });

      final data = resp.data as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      await _storage.writeSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        userId: user['id'] as String,
        email: user['email'] as String,
        fullName: user['full_name'] as String? ?? '',
        role: user['role'] as String? ?? 'traveler',
      );
      state = AuthState(
        status: AuthStatus.signedIn,
        userName: user['full_name'] as String?,
        userEmail: user['email'] as String?,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString() ?? e.message
          : e.message;
      state = state.copyWith(status: AuthStatus.error, error: msg);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  /// Dev-only email/password fallback so the app is testable without the IdP.
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.signingIn, error: null);
    try {
      final resp = await _api.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = resp.data as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      await _storage.writeSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        userId: user['id'] as String,
        email: user['email'] as String,
        fullName: user['full_name'] as String? ?? '',
        role: user['role'] as String? ?? 'traveler',
      );
      state = AuthState(
        status: AuthStatus.signedIn,
        userName: user['full_name'] as String?,
        userEmail: user['email'] as String?,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString() ?? e.message
          : e.message;
      state = state.copyWith(status: AuthStatus.error, error: msg);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _storage.clear();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  String _generateVerifier() => _randomString(48);

  String _challenge(String verifier) =>
      base64Url.encode(sha256.convert(utf8.encode(verifier)).bytes).replaceAll('=', '');

  String _randomString(int len) {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final rng = Random.secure();
    return List.generate(len, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final storage = ref.watch(authStorageProvider);
  final api = ref.watch(apiClientProvider);
  return AuthController(storage, api);
});
