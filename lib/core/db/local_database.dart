import 'package:sqflite/sqflite.dart';

/// Base local del teléfono (RN-25, RN-28).
///
/// Tres zonas:
/// - `records`: copia de las fuentes de `GET /sync/changes` (una fila por
///   `source` + `id`, el registro completo en JSON). Upsert por id.
/// - `outbox`: cola de hechos por enviar, en orden (`seq`).
/// - `kv`: cursor de sync, perfil (`/auth/me`), preferencias.
class LocalDatabase {
  LocalDatabase(this.db);

  final Database db;

  static const int version = 1;

  static Future<LocalDatabase> open({
    required DatabaseFactory factory,
    required String path,
    bool singleInstance = true,
  }) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        singleInstance: singleInstance,
        onCreate: (db, _) => _create(db),
      ),
    );
    return LocalDatabase(db);
  }

  static Future<void> _create(Database db) async {
    await db.execute('''
      CREATE TABLE records (
        source TEXT NOT NULL,
        id TEXT NOT NULL,
        project_id TEXT,
        data TEXT NOT NULL,
        PRIMARY KEY (source, id)
      )
    ''');
    await db.execute(
      'CREATE INDEX records_project ON records (source, project_id)',
    );
    await db.execute('''
      CREATE TABLE outbox (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT NOT NULL,
        kind TEXT NOT NULL,
        method TEXT NOT NULL,
        path TEXT NOT NULL,
        body TEXT,
        label TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        error_status INTEGER,
        parent_id TEXT,
        file_path TEXT,
        patches TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX outbox_status ON outbox (status, seq)');
    await db.execute(
      'CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
  }

  /// Borra todo lo local (cambio de usuario o de empresa). Conserva las
  /// preferencias del teléfono ([keepKeys]).
  Future<void> wipe({
    List<String> keepKeys = const ['app.locale', 'app.simulateOffline', 'app.lastCuit', 'app.lastIdentifier'],
  }) async {
    await db.transaction((txn) async {
      await txn.delete('records');
      await txn.delete('outbox');
      await txn.delete(
        'kv',
        where: 'key NOT IN (${List.filled(keepKeys.length, '?').join(',')})',
        whereArgs: keepKeys,
      );
    });
  }

  Future<void> close() => db.close();
}
