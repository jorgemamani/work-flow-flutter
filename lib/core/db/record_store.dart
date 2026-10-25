import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

typedef JsonMap = Map<String, dynamic>;

/// Cambio local optimista sobre una fila de `records`: se aplica al encolar un
/// hecho y se vuelve a aplicar después de cada sync mientras el hecho siga en
/// la cola, para que la pantalla muestre lo que el usuario hizo sin señal.
class RecordPatch {
  const RecordPatch({
    required this.source,
    required this.id,
    required this.fields,
  });

  final String source;
  final String id;
  final JsonMap fields;

  Map<String, dynamic> toJson() => {'s': source, 'i': id, 'f': fields};

  factory RecordPatch.fromJson(Map<String, dynamic> json) => RecordPatch(
        source: json['s'] as String,
        id: json['i'] as String,
        fields: Map<String, dynamic>.from(json['f'] as Map),
      );
}

/// Acceso a la copia local de las fuentes de sync y al almacén clave/valor.
class RecordStore {
  RecordStore(this._local);

  final LocalDatabase _local;
  final _changes = StreamController<Set<String>>.broadcast();

  Database get _db => _local.db;

  /// Emite las fuentes que cambiaron (para refrescar pantallas).
  Stream<Set<String>> get changes => _changes.stream;

  void notify(Set<String> sources) {
    if (sources.isNotEmpty) _changes.add(sources);
  }

  static String? projectOf(JsonMap row) =>
      (row['projectId'] ?? row['effectiveProjectId'] ?? row['destinationProjectId'])
          as String?;

  Future<void> upsertAll(
    DatabaseExecutor ex,
    String source,
    Iterable<JsonMap> rows,
  ) async {
    final batch = ex.batch();
    for (final row in rows) {
      batch.insert(
        'records',
        {
          'source': source,
          'id': row['id'] as String,
          'project_id': projectOf(row),
          'data': jsonEncode(row),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll(
    DatabaseExecutor ex,
    String source,
    Iterable<String> ids,
  ) async {
    final batch = ex.batch();
    for (final id in ids) {
      batch.delete(
        'records',
        where: 'source = ? AND id = ?',
        whereArgs: [source, id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Borra las filas optimistas (`_local: true`). Devuelve sus fuentes.
  Future<Set<String>> deleteLocalRows(DatabaseExecutor ex) async {
    const where = "data LIKE '%\"_local\":true%'";
    final rows = await ex.query('records', columns: ['source'], where: where, distinct: true);
    await ex.delete('records', where: where);
    return {for (final r in rows) r['source'] as String};
  }

  /// Mezcla `patch.fields` en la fila (o la crea si no existe).
  Future<void> applyPatch(DatabaseExecutor ex, RecordPatch patch) async {
    final current = await _get(ex, patch.source, patch.id);
    final merged = <String, dynamic>{
      ...?current,
      ...patch.fields,
      'id': patch.id,
    };
    await upsertAll(ex, patch.source, [merged]);
  }

  Future<JsonMap?> _get(DatabaseExecutor ex, String source, String id) async {
    final rows = await ex.query(
      'records',
      columns: ['data'],
      where: 'source = ? AND id = ?',
      whereArgs: [source, id],
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as JsonMap;
  }

  Future<JsonMap?> get(String source, String id) => _get(_db, source, id);

  Future<List<JsonMap>> all(String source, {String? projectId}) async {
    final rows = await _db.query(
      'records',
      columns: ['data'],
      where: projectId == null ? 'source = ?' : 'source = ? AND project_id = ?',
      whereArgs: projectId == null ? [source] : [source, projectId],
    );
    return [for (final r in rows) jsonDecode(r['data'] as String) as JsonMap];
  }

  Future<Map<String, JsonMap>> byId(String source) async {
    final rows = await all(source);
    return {for (final r in rows) r['id'] as String: r};
  }

  Future<int> count(String source) async {
    final r = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM records WHERE source = ?',
      [source],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  // ── kv ─────────────────────────────────────────────────────────────────────

  Future<String?> getValue(String key, {DatabaseExecutor? ex}) async {
    final rows = await (ex ?? _db).query(
      'kv',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setValue(String key, String? value, {DatabaseExecutor? ex}) async {
    final e = ex ?? _db;
    if (value == null) {
      await e.delete('kv', where: 'key = ?', whereArgs: [key]);
    } else {
      await e.insert(
        'kv',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final v = await getValue(key);
    return v == null ? null : jsonDecode(v) as Map<String, dynamic>;
  }

  Future<void> setJson(String key, Map<String, dynamic>? value) =>
      setValue(key, value == null ? null : jsonEncode(value));

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) =>
      _db.transaction(action);
}

/// Claves del almacén `kv`.
abstract final class KvKeys {
  static const syncCursor = 'sync.cursor';
  static const lastSyncAt = 'sync.lastSyncAt';
  static const profile = 'auth.profile';
  static const selectedProjectId = 'app.selectedProjectId';
  static const simulateOffline = 'app.simulateOffline';
  static const locale = 'app.locale';
  static const ownerKey = 'app.ownerKey';
  static const lastCuit = 'app.lastCuit';
  static const lastIdentifier = 'app.lastIdentifier';
}
