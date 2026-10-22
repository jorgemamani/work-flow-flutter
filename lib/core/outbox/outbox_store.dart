import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../db/local_database.dart';
import '../db/record_store.dart';
import '../sync/sync_applier.dart';
import 'outbox_op.dart';

class OutboxCounts {
  const OutboxCounts({this.pending = 0, this.failed = 0});

  final int pending;

  /// Fallidos y descartados: lo que el usuario tiene que mirar.
  final int failed;

  @override
  bool operator ==(Object other) =>
      other is OutboxCounts &&
      other.pending == pending &&
      other.failed == failed;

  @override
  int get hashCode => Object.hash(pending, failed);
}

/// Cola local de hechos (RN-25). Persistida en SQLite: sobrevive a cierres
/// de la app y a días sin señal.
class OutboxStore implements PendingPatchSource {
  OutboxStore(this._local, this._records, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final LocalDatabase _local;
  final RecordStore _records;
  final DateTime Function() _clock;
  final _counts = StreamController<OutboxCounts>.broadcast();

  Database get _db => _local.db;

  Stream<OutboxCounts> get counts => _counts.stream;

  Future<void> _emit() async => _counts.add(await currentCounts());

  /// Encola uno o más hechos en orden y aplica sus cambios optimistas, en una
  /// sola transacción.
  Future<void> enqueue(List<OutboxOp> ops) async {
    final touched = <String>{};
    await _db.transaction((txn) async {
      for (final op in ops) {
        await txn.insert('outbox', op.toRow(_clock()));
        for (final p in op.patches) {
          await _records.applyPatch(txn, p);
          touched.add(p.source);
        }
      }
    });
    _records.notify(touched);
    await _emit();
  }

  Future<OutboxOp?> nextPending() async {
    final rows = await _db.query(
      'outbox',
      where: 'status = ?',
      whereArgs: [OutboxStatus.pending.name],
      orderBy: 'seq ASC',
      limit: 1,
    );
    return rows.isEmpty ? null : OutboxOp.fromRow(rows.first);
  }

  Future<List<OutboxOp>> list({Set<OutboxStatus>? statuses}) async {
    final rows = await _db.query('outbox', orderBy: 'seq ASC');
    return [
      for (final r in rows)
        if (statuses == null ||
            statuses.contains(OutboxStatus.values.byName(r['status'] as String)))
          OutboxOp.fromRow(r),
    ];
  }

  /// Enviado (created true o false): sale de la cola.
  Future<void> complete(int seq) async {
    await _db.delete('outbox', where: 'seq = ?', whereArgs: [seq]);
    await _emit();
  }

  /// Aceptado pero descartado por la API: queda como aviso.
  Future<void> markDiscarded(int seq, String message) async {
    await _db.update(
      'outbox',
      {
        'status': OutboxStatus.discarded.name,
        'last_error': message,
        'updated_at': _now(),
      },
      where: 'seq = ?',
      whereArgs: [seq],
    );
    await _emit();
  }

  /// Rechazo de negocio (4xx): queda como fallido visible. Los hijos
  /// pendientes (fotos de ese hecho) fallan con él.
  Future<void> markFailed(int seq, {int? status, required String message}) async {
    await _db.transaction((txn) async {
      final rows = await txn.query('outbox', where: 'seq = ?', whereArgs: [seq]);
      if (rows.isEmpty) return;
      final id = rows.first['id'] as String;
      await txn.update(
        'outbox',
        {
          'status': OutboxStatus.failed.name,
          'last_error': message,
          'error_status': status,
          'attempts': (rows.first['attempts'] as int? ?? 0) + 1,
          'updated_at': _now(),
        },
        where: 'seq = ?',
        whereArgs: [seq],
      );
      await txn.update(
        'outbox',
        {
          'status': OutboxStatus.failed.name,
          'last_error': message,
          'error_status': status,
          'updated_at': _now(),
        },
        where: 'parent_id = ? AND status = ?',
        whereArgs: [id, OutboxStatus.pending.name],
      );
    });
    await _emit();
  }

  /// Error transitorio (5xx / sin red): sigue pendiente, mismo id.
  Future<void> markRetry(int seq, String message) async {
    await _db.rawUpdate(
      'UPDATE outbox SET attempts = attempts + 1, last_error = ?, updated_at = ? WHERE seq = ?',
      [message, _now(), seq],
    );
  }

  /// El usuario pide reintentar un fallido: vuelve a la cola con el mismo id
  /// y en su lugar original (el orden es por `seq`).
  Future<void> retry(int seq) async {
    await _db.update(
      'outbox',
      {
        'status': OutboxStatus.pending.name,
        'last_error': null,
        'error_status': null,
        'updated_at': _now(),
      },
      where: 'seq = ?',
      whereArgs: [seq],
    );
    await _emit();
  }

  /// El usuario descarta un fallido o un aviso.
  Future<void> dismiss(int seq) async {
    await _db.delete('outbox', where: 'seq = ?', whereArgs: [seq]);
    await _emit();
  }

  Future<OutboxCounts> currentCounts() async {
    final rows = await _db.rawQuery(
      'SELECT status, COUNT(*) AS c FROM outbox GROUP BY status',
    );
    var pending = 0;
    var failed = 0;
    for (final r in rows) {
      final c = r['c'] as int? ?? 0;
      if (r['status'] == OutboxStatus.pending.name) {
        pending += c;
      } else {
        failed += c;
      }
    }
    return OutboxCounts(pending: pending, failed: failed);
  }

  @override
  Future<List<RecordPatch>> pendingPatches(DatabaseExecutor ex) async {
    final rows = await ex.query(
      'outbox',
      columns: ['patches'],
      where: 'status = ? AND patches IS NOT NULL',
      whereArgs: [OutboxStatus.pending.name],
      orderBy: 'seq ASC',
    );
    return [
      for (final r in rows)
        for (final p in jsonDecode(r['patches'] as String) as List)
          RecordPatch.fromJson(p as Map<String, dynamic>),
    ];
  }

  String _now() => _clock().toUtc().toIso8601String();
}
