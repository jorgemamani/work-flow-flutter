import 'package:sqflite/sqflite.dart';

import '../db/record_store.dart';
import 'sync_page.dart';

/// Devuelve los cambios optimistas de los hechos que siguen en la cola.
abstract interface class PendingPatchSource {
  Future<List<RecordPatch>> pendingPatches(DatabaseExecutor ex);
}

/// Aplica una página de `/sync/changes` a la base local (contrato §3):
/// upsert por id, borrado de `deleted`, cursor guardado, todo en una
/// transacción. Después vuelve a aplicar los cambios optimistas de lo que
/// todavía no se envió, para que la sync no "deshaga" lo hecho sin señal.
class SyncApplier {
  SyncApplier(this._store, this._pending, {Set<String>? sources})
      : _sources = sources ?? SyncSources.all;

  final RecordStore _store;
  final PendingPatchSource _pending;
  final Set<String> _sources;

  /// Devuelve las fuentes tocadas. Con [purgeLocal] (primera página de una
  /// descarga completa) borra antes las filas creadas en el teléfono: las que
  /// llegaron a la API vuelven con esta descarga, y las rechazadas desaparecen.
  Future<Set<String>> apply(SyncPage page, {bool purgeLocal = false}) async {
    final touched = <String>{};
    await _store.transaction((txn) async {
      if (purgeLocal) touched.addAll(await _store.deleteLocalRows(txn));
      for (final entry in page.changes.entries) {
        if (!_sources.contains(entry.key) || entry.value.isEmpty) continue;
        await _store.upsertAll(txn, entry.key, entry.value);
        touched.add(entry.key);
      }
      for (final entry in page.deleted.entries) {
        if (!_sources.contains(entry.key) || entry.value.isEmpty) continue;
        await _store.deleteAll(txn, entry.key, entry.value);
        touched.add(entry.key);
      }
      if (touched.isNotEmpty || purgeLocal) {
        for (final patch in await _pending.pendingPatches(txn)) {
          await _store.applyPatch(txn, patch);
          touched.add(patch.source);
        }
      }
      await _store.setValue(KvKeys.syncCursor, page.cursor, ex: txn);
    });
    return touched;
  }
}
