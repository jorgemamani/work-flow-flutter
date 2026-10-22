import 'dart:async';

import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../network/api_paths.dart';
import '../network/offline_guard_interceptor.dart';
import '../outbox/outbox_processor.dart';
import 'token_store.dart';

class Membership {
  const Membership({required this.tenantId, required this.tenantName});

  final String tenantId;
  final String tenantName;

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        tenantId: j['tenantId'] as String,
        tenantName: j['tenantName'] as String? ?? '',
      );
}

/// Sesión larga (contrato §2, RN-28): access de 15 min, refresh rotativo de
/// 30 días. Sin señal la sesión NO se cierra: solo se da por vencida cuando
/// la API rechaza el refresh.
class SessionManager implements SessionRefresher {
  SessionManager({
    required Dio authDio,
    required TokenStore tokens,
    DateTime Function()? clock,
  })  : _dio = authDio,
        _tokens = tokens,
        _clock = clock ?? DateTime.now;

  /// Dio sin interceptor de auth (login y refresh no llevan Bearer).
  final Dio _dio;
  final TokenStore _tokens;
  final DateTime Function() _clock;

  /// Margen para refrescar antes de que venza el access token.
  static const refreshMargin = Duration(seconds: 60);

  final _expired = StreamController<void>.broadcast();
  Future<RefreshOutcome>? _refreshing;

  /// Emite cuando la API rechazó el refresh: hay que volver a ingresar.
  Stream<void> get onExpired => _expired.stream;

  Future<bool> hasSession() async => (await _tokens.read()) != null;

  Future<String?> accessToken() async => (await _tokens.read())?.accessToken;

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<List<Membership>> loginField({
    required String cuit,
    required String documentNumber,
    required String pin,
  }) =>
      _login({'cuit': cuit, 'documentNumber': documentNumber, 'pin': pin});

  Future<List<Membership>> loginOffice({
    required String email,
    required String password,
    String? cuit,
  }) =>
      _login({
        'email': email,
        'password': password,
        if (cuit != null && cuit.isNotEmpty) 'cuit': cuit,
      });

  Future<List<Membership>> _login(Map<String, dynamic> body) async {
    final data = await _post(ApiPaths.login, body);
    await _save(data);
    return [
      for (final m in data['memberships'] as List? ?? const [])
        Membership.fromJson(m as Map<String, dynamic>),
    ];
  }

  /// Nombre de la empresa al tipear el CUIT (público).
  Future<String?> resolveTenant(String cuit) async {
    try {
      final r = await _dio.get<dynamic>(
        ApiPaths.resolveTenant,
        queryParameters: {'cuit': cuit},
      );
      final data = (r.data as Map)['data'];
      return data is Map ? data['name'] as String? : null;
    } on DioException {
      return null;
    }
  }

  Future<void> switchTenant(String tenantId) async {
    final access = await accessToken();
    final data = await _post(
      ApiPaths.switchTenant,
      {'tenantId': tenantId},
      bearer: access,
    );
    await _save(data);
  }

  Future<void> logout() async {
    final t = await _tokens.read();
    await _tokens.clear();
    if (t == null) return;
    try {
      await _dio.post<dynamic>(
        ApiPaths.logout,
        data: {'refreshToken': t.refreshToken},
      );
    } on DioException {
      // Sin señal: el refresh vence solo a los 30 días.
    }
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  @override
  Future<RefreshOutcome> ensureFresh() async {
    final t = await _tokens.read();
    if (t == null) return RefreshOutcome.expired;
    if (t.accessToken.isNotEmpty &&
        t.accessExpiresAt.isAfter(_clock().add(refreshMargin))) {
      return RefreshOutcome.ok;
    }
    return forceRefresh();
  }

  /// Un solo refresh a la vez: el token rota, y usar dos veces el mismo
  /// revoca la sesión entera.
  @override
  Future<RefreshOutcome> forceRefresh() {
    final running = _refreshing;
    if (running != null) return running;
    final run = _refresh().whenComplete(() => _refreshing = null);
    _refreshing = run;
    return run;
  }

  Future<RefreshOutcome> _refresh() async {
    final t = await _tokens.read();
    if (t == null) return RefreshOutcome.expired;
    try {
      final r = await _dio.post<dynamic>(
        ApiPaths.refresh,
        data: {'refreshToken': t.refreshToken},
      );
      await _save((r.data as Map)['data'] as Map<String, dynamic>);
      return RefreshOutcome.ok;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null || status >= 500 || status == 408 || status == 429) {
        return RefreshOutcome.offline;
      }
      // 400/401/403: el refresh no sirve más.
      await _tokens.clear();
      _expired.add(null);
      return RefreshOutcome.expired;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? bearer,
  }) async {
    try {
      final r = await _dio.post<dynamic>(
        path,
        data: body,
        options: bearer == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $bearer'}),
      );
      return (r.data as Map)['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (isNetworkError(e)) throw const OfflineException();
      final data = e.response?.data;
      final msg = data is Map ? data['message'] : null;
      throw ApiException(
        msg is List ? msg.join('\n') : (msg as String? ?? 'Error'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> _save(Map<String, dynamic> data) async {
    final expiresIn = (data['expiresIn'] as num?)?.toInt() ?? 900;
    await _tokens.write(
      SessionTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        accessExpiresAt: _clock().add(Duration(seconds: expiresIn)),
      ),
    );
  }
}
