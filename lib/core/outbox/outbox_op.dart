import 'dart:convert';

import '../db/record_store.dart';

enum OutboxKind {
  /// Un hecho JSON: `PUT /<recurso>/<id>` (o un POST idempotente).
  request,

  /// Una foto: registrar → subir a R2 → confirmar (contrato §5).
  attachment,
}

enum OutboxStatus {
  pending,

  /// Rechazado por la API (4xx). Se muestra al usuario (RN-25).
  failed,

  /// Aceptado pero descartado por la API (RN-27: remito ya recibido). Aviso.
  discarded,
}

/// Qué se muestra en la lista de pendientes / fallidos: una clave de
/// traducción y sus argumentos (la cola sobrevive a un cambio de idioma).
class OutboxLabel {
  const OutboxLabel(this.key, [this.args = const {}]);

  final String key;
  final Map<String, String> args;

  String encode() => jsonEncode({'k': key, 'a': args});

  factory OutboxLabel.decode(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return OutboxLabel(
      j['k'] as String,
      Map<String, String>.from(j['a'] as Map? ?? {}),
    );
  }
}

class OutboxOp {
  const OutboxOp({
    this.seq,
    required this.id,
    required this.kind,
    required this.method,
    required this.path,
    required this.label,
    required this.occurredAt,
    this.body,
    this.status = OutboxStatus.pending,
    this.attempts = 0,
    this.lastError,
    this.errorStatus,
    this.parentId,
    this.filePath,
    this.patches = const [],
  });

  final int? seq;

  /// Id del hecho o del adjunto (UUIDv7 del cliente). No cambia en reintentos.
  final String id;
  final OutboxKind kind;
  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final OutboxLabel label;
  final DateTime occurredAt;
  final OutboxStatus status;
  final int attempts;
  final String? lastError;
  final int? errorStatus;

  /// Hecho del que depende (ej. la verificación dueña de una foto). Si el
  /// padre falla, el hijo falla con él.
  final String? parentId;

  /// Foto comprimida en el teléfono (solo `attachment`).
  final String? filePath;

  /// Cambios optimistas sobre la base local mientras siga pendiente.
  final List<RecordPatch> patches;

  Map<String, Object?> toRow(DateTime now) => {
        'id': id,
        'kind': kind.name,
        'method': method,
        'path': path,
        'body': body == null ? null : jsonEncode(body),
        'label': label.encode(),
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'status': status.name,
        'attempts': attempts,
        'last_error': lastError,
        'error_status': errorStatus,
        'parent_id': parentId,
        'file_path': filePath,
        'patches': patches.isEmpty
            ? null
            : jsonEncode([for (final p in patches) p.toJson()]),
        'created_at': now.toUtc().toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
      };

  factory OutboxOp.fromRow(Map<String, Object?> row) => OutboxOp(
        seq: row['seq'] as int?,
        id: row['id'] as String,
        kind: OutboxKind.values.byName(row['kind'] as String),
        method: row['method'] as String,
        path: row['path'] as String,
        body: row['body'] == null
            ? null
            : jsonDecode(row['body'] as String) as Map<String, dynamic>,
        label: OutboxLabel.decode(row['label'] as String),
        occurredAt: DateTime.parse(row['occurred_at'] as String),
        status: OutboxStatus.values.byName(row['status'] as String),
        attempts: row['attempts'] as int? ?? 0,
        lastError: row['last_error'] as String?,
        errorStatus: row['error_status'] as int?,
        parentId: row['parent_id'] as String?,
        filePath: row['file_path'] as String?,
        patches: row['patches'] == null
            ? const []
            : [
                for (final p in jsonDecode(row['patches'] as String) as List)
                  RecordPatch.fromJson(p as Map<String, dynamic>),
              ],
      );
}
