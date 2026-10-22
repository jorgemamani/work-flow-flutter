import 'dart:async';

import 'outbox_op.dart';
import 'outbox_store.dart';

/// Respuesta HTTP cruda (la cola decide qué hacer con cada código).
class TransportResponse {
  const TransportResponse(this.status, [this.data]);

  final int status;
  final dynamic data;

  bool get ok => status >= 200 && status < 300;

  Map<String, dynamic> get meta {
    final d = data;
    if (d is Map && d['meta'] is Map) {
      return Map<String, dynamic>.from(d['meta'] as Map);
    }
    return const {};
  }

  String get message {
    final d = data;
    if (d is Map) {
      final m = d['message'];
      if (m is String) return m;
      if (m is List) return m.join('\n');
    }
    return 'HTTP $status';
  }
}

/// Sin respuesta del servidor (sin red, timeout, DNS…).
class OfflineException implements Exception {
  const OfflineException([this.message = 'offline']);

  final String message;

  @override
  String toString() => 'OfflineException($message)';
}

abstract interface class OutboxTransport {
  /// Llamada a la API. Devuelve cualquier código; tira [OfflineException] si
  /// no hubo respuesta.
  Future<TransportResponse> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });

  /// `PUT` del binario a la URL firmada de R2 (sin header de auth).
  Future<TransportResponse> upload(String url, String filePath, String mimeType);

  Future<bool> fileExists(String filePath);
}

enum RefreshOutcome { ok, offline, expired }

abstract interface class SessionRefresher {
  /// Asegura un access token vigente (refresca si venció o está por vencer).
  Future<RefreshOutcome> ensureFresh();

  /// Fuerza un refresh (después de un 401).
  Future<RefreshOutcome> forceRefresh();
}

enum DrainStop { empty, offline, sessionExpired, busy }

class DrainReport {
  const DrainReport({
    this.sent = 0,
    this.failed = 0,
    this.discarded = 0,
    required this.stop,
  });

  final int sent;
  final int failed;
  final int discarded;
  final DrainStop stop;
}

/// Reintentos de un 409 al confirmar una foto antes de darla por fallida.
const maxConfirmConflicts = 5;

/// Drena la cola en orden (contrato §4):
/// - 2xx (`created` true o false) → sale de la cola.
/// - 4xx → fallido visible; se sigue con el siguiente.
/// - 5xx / sin red → se corta el drenado y se reintenta después, mismo id.
/// - 401 → refresh y un reintento; si el refresh no anda, se corta.
class OutboxProcessor {
  OutboxProcessor({
    required OutboxStore store,
    required OutboxTransport transport,
    required SessionRefresher session,
  })  : _store = store,
        _transport = transport,
        _session = session;

  final OutboxStore _store;
  final OutboxTransport _transport;
  final SessionRefresher _session;

  Future<DrainReport>? _running;

  bool get isRunning => _running != null;

  /// Un solo drenado a la vez: llamadas concurrentes esperan el mismo.
  Future<DrainReport> drain() {
    final current = _running;
    if (current != null) return current;
    final run = _drain().whenComplete(() => _running = null);
    _running = run;
    return run;
  }

  Future<DrainReport> _drain() async {
    var sent = 0;
    var failed = 0;
    var discarded = 0;
    DrainReport report(DrainStop stop) =>
        DrainReport(sent: sent, failed: failed, discarded: discarded, stop: stop);

    if (await _store.nextPending() == null) return report(DrainStop.empty);

    // Contrato §2: refrescar la sesión ANTES de drenar.
    switch (await _session.ensureFresh()) {
      case RefreshOutcome.ok:
        break;
      case RefreshOutcome.offline:
        return report(DrainStop.offline);
      case RefreshOutcome.expired:
        return report(DrainStop.sessionExpired);
    }

    while (true) {
      final op = await _store.nextPending();
      if (op == null) return report(DrainStop.empty);

      var outcome = await _attempt(op);
      if (outcome is _Unauthorized) {
        final r = await _session.forceRefresh();
        if (r == RefreshOutcome.offline) {
          await _store.markRetry(op.seq!, 'offline');
          return report(DrainStop.offline);
        }
        if (r == RefreshOutcome.expired) return report(DrainStop.sessionExpired);
        outcome = await _attempt(op);
        if (outcome is _Unauthorized) return report(DrainStop.sessionExpired);
      }

      switch (outcome) {
        case _Done(:final discardedMessage):
          if (discardedMessage != null) {
            await _store.markDiscarded(op.seq!, discardedMessage);
            discarded++;
          } else {
            await _store.complete(op.seq!);
            sent++;
          }
        case _Rejected(:final status, :final message):
          await _store.markFailed(op.seq!, status: status, message: message);
          failed++;
        case _Retry(:final message):
          await _store.markRetry(op.seq!, message);
          return report(DrainStop.offline);
        case _Unauthorized():
          return report(DrainStop.sessionExpired);
      }
    }
  }

  Future<_Outcome> _attempt(OutboxOp op) async {
    try {
      return switch (op.kind) {
        OutboxKind.request => await _sendRequest(op),
        OutboxKind.attachment => await _sendAttachment(op),
      };
    } on OfflineException catch (e) {
      return _Retry(e.message);
    }
  }

  Future<_Outcome> _sendRequest(OutboxOp op) async {
    final r = await _transport.send(op.method, op.path, body: op.body);
    if (r.ok) {
      // RN-27: la segunda recepción de un remito se guarda descartada.
      if (r.meta['discarded'] == true) {
        return _Done(discardedMessage: r.meta['message'] as String? ?? 'discarded');
      }
      return const _Done();
    }
    return _classify(r);
  }

  Future<_Outcome> _sendAttachment(OutboxOp op) async {
    final file = op.filePath;
    if (file == null || !await _transport.fileExists(file)) {
      return const _Rejected(null, 'photo_missing');
    }
    final register = await _transport.send('PUT', op.path, body: op.body);
    if (!register.ok) return _classify(register);

    final uploadUrl = register.meta['uploadUrl'] as String?;
    if (uploadUrl != null) {
      final mime = op.body?['mimeType'] as String? ?? 'image/jpeg';
      final up = await _transport.upload(uploadUrl, file, mime);
      // La URL vence a los 5 min: cualquier rechazo de R2 se resuelve
      // registrando de nuevo en el próximo intento.
      if (!up.ok) return _Retry('upload ${up.status}');
    }

    final confirm = await _transport.send('POST', '${op.path}/confirm');
    if (confirm.ok) return const _Done();
    if (confirm.status == 409) {
      // El archivo todavía no está en R2: repetir la subida.
      if (op.attempts + 1 >= maxConfirmConflicts) {
        return _Rejected(409, confirm.message);
      }
      return const _Retry('confirm 409');
    }
    return _classify(confirm);
  }

  _Outcome _classify(TransportResponse r) {
    if (r.status == 401) return const _Unauthorized();
    if (r.status == 408 || r.status == 429 || r.status >= 500) {
      return _Retry('HTTP ${r.status}');
    }
    return _Rejected(r.status, r.message);
  }
}

sealed class _Outcome {
  const _Outcome();
}

class _Done extends _Outcome {
  const _Done({this.discardedMessage});

  final String? discardedMessage;
}

class _Rejected extends _Outcome {
  const _Rejected(this.status, this.message);

  final int? status;
  final String message;
}

class _Retry extends _Outcome {
  const _Retry(this.message);

  final String message;
}

class _Unauthorized extends _Outcome {
  const _Unauthorized();
}
