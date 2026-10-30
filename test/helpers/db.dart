import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:work_flow/core/db/local_database.dart';
import 'package:work_flow/core/db/record_store.dart';
import 'package:work_flow/core/outbox/outbox_store.dart';

/// Base SQLite en memoria (la misma que en el teléfono, vía FFI).
Future<(LocalDatabase, RecordStore, OutboxStore)> openTestDb() async {
  sqfliteFfiInit();
  final local = await LocalDatabase.open(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
    singleInstance: false,
  );
  final records = RecordStore(local);
  final outbox = OutboxStore(local, records);
  return (local, records, outbox);
}
