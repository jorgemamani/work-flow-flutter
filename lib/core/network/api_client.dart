import 'dart:io';

import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../outbox/outbox_processor.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_page.dart';
import 'api_paths.dart';
import 'offline_guard_interceptor.dart';

/// Llamadas en línea (perfil, sync, fotos vigentes). Las escrituras de campo
/// NO pasan por acá: van a la cola.
class ApiClient implements SyncFetcher, OutboxTransport {
  ApiClient(this._dio, this._r2);

  final Dio _dio;

  /// Dio sin auth para las URLs firmadas de R2.
  final Dio _r2;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final r = await _dio.get<dynamic>(path, queryParameters: query);
      return _unwrap(r.data);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  Future<dynamic> post(String path, {Object? body}) async {
    try {
      final r = await _dio.post<dynamic>(path, data: body);
      return _unwrap(r.data);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    try {
      final r = await _dio.patch<dynamic>(path, data: body);
      return _unwrap(r.data);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  /// Descarga un archivo (foto vigente) a disco.
  Future<void> download(String url, String savePath) async {
    try {
      await _r2.download(url, savePath);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  // ── SyncFetcher ────────────────────────────────────────────────────────────

  @override
  Future<SyncPage> fetch(String? cursor) async {
    try {
      final r = await _dio.get<dynamic>(
        ApiPaths.syncChanges,
        queryParameters: {if (cursor != null) 'cursor': cursor},
      );
      return SyncPage.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  // ── OutboxTransport ────────────────────────────────────────────────────────

  @override
  Future<TransportResponse> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final r = await _dio.request<dynamic>(
        path,
        data: body,
        options: Options(method: method),
      );
      return TransportResponse(r.statusCode ?? 200, r.data);
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw OfflineException(e.message ?? 'offline');
      return TransportResponse(res.statusCode ?? 0, res.data);
    }
  }

  @override
  Future<TransportResponse> upload(
    String url,
    String filePath,
    String mimeType,
  ) async {
    final file = File(filePath);
    final length = await file.length();
    try {
      final r = await _r2.put<dynamic>(
        url,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentTypeHeader: mimeType,
            Headers.contentLengthHeader: length,
          },
          responseType: ResponseType.plain,
        ),
      );
      return TransportResponse(r.statusCode ?? 200);
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw OfflineException(e.message ?? 'offline');
      return TransportResponse(res.statusCode ?? 0, res.data);
    }
  }

  @override
  Future<bool> fileExists(String filePath) => File(filePath).exists();

  // ── Helpers ────────────────────────────────────────────────────────────────

  static dynamic _unwrap(dynamic body) =>
      body is Map && body.containsKey('data') ? body['data'] : body;

  static Exception _error(DioException e) {
    if (isNetworkError(e)) return OfflineException(e.message ?? 'offline');
    final status = e.response?.statusCode;
    if (status == 401) return const SessionExpiredException();
    final data = e.response?.data;
    final msg = data is Map ? data['message'] : null;
    return ApiException(
      msg is List ? msg.join('\n') : (msg as String? ?? 'HTTP $status'),
      statusCode: status,
    );
  }
}
