import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Id de un hecho o adjunto generado en el teléfono (UUIDv7, contrato §4).
String newId() => _uuid.v7();

/// `occurredAt` con el reloj del teléfono, en ISO 8601 con zona.
String nowIso([DateTime? at]) => (at ?? DateTime.now()).toUtc().toIso8601String();
