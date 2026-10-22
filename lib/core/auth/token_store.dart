import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
}

/// Tokens en el llavero del sistema (Keychain / Keystore), nunca en SQLite.
abstract interface class TokenStore {
  Future<SessionTokens?> read();
  Future<void> write(SessionTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _access = 'auth.accessToken';
  static const _refresh = 'auth.refreshToken';
  static const _expires = 'auth.accessExpiresAt';

  @override
  Future<SessionTokens?> read() async {
    final refresh = await _storage.read(key: _refresh);
    if (refresh == null) return null;
    return SessionTokens(
      accessToken: await _storage.read(key: _access) ?? '',
      refreshToken: refresh,
      accessExpiresAt: DateTime.tryParse(await _storage.read(key: _expires) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  Future<void> write(SessionTokens tokens) async {
    // El refresh rota (contrato §2): guardarlo siempre primero.
    await _storage.write(key: _refresh, value: tokens.refreshToken);
    await _storage.write(key: _access, value: tokens.accessToken);
    await _storage.write(
      key: _expires,
      value: tokens.accessExpiresAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
    await _storage.delete(key: _expires);
  }
}
