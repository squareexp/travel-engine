import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  AuthStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'twende.access_token';
  static const _refreshKey = 'twende.refresh_token';
  static const _userIdKey = 'twende.user_id';
  static const _userEmailKey = 'twende.user_email';
  static const _userNameKey = 'twende.user_name';
  static const _userRoleKey = 'twende.user_role';

  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String fullName,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _userNameKey, value: fullName),
      _storage.write(key: _userRoleKey, value: role),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<Map<String, String?>> readProfile() async {
    return {
      'id': await _storage.read(key: _userIdKey),
      'email': await _storage.read(key: _userEmailKey),
      'name': await _storage.read(key: _userNameKey),
      'role': await _storage.read(key: _userRoleKey),
    };
  }

  Future<void> clear() => _storage.deleteAll();
}

final authStorageProvider = Provider<AuthStorage>((_) => AuthStorage());
