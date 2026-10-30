import '../db/record_store.dart';
import 'sync_applier.dart';
import 'sync_page.dart';

/// Pide una página de cambios desde un cursor (null = descarga completa).
abstract interface class SyncFetcher {
  Future<SyncPage> fetch(String? cursor);
}

class SyncResult {
  const SyncResult({required this.pages, required this.touched});

  final int pages;
  final Set<String> touched;
}

/// Baja cambios hasta quedar al día: repite con el cursor mientras
/// `hasMore` sea true (contrato §3).
class SyncEngine {
  SyncEngine({
    required SyncFetcher fetcher,
    required SyncApplier applier,
    required RecordStore store,
    DateTime Function()? clock,
    this.maxPages = 500,
  })  : _fetcher = fetcher,
        _applier = applier,
        _store = store,
        _clock = clock ?? DateTime.now;

  final SyncFetcher _fetcher;
  final SyncApplier _applier;
  final RecordStore _store;
  final DateTime Function() _clock;

  /// Tope de seguridad contra un servidor que nunca dice `hasMore: false`.
  final int maxPages;

  Future<SyncResult> pull() async {
    var cursor = await _store.getValue(KvKeys.syncCursor);
    final touched = <String>{};
    var pages = 0;
    while (true) {
      final page = await _fetcher.fetch(cursor);
      touched.addAll(await _applier.apply(page, purgeLocal: cursor == null));
      cursor = page.cursor;
      pages++;
      if (!page.hasMore || pages >= maxPages) break;
    }
    await _store.setValue(KvKeys.lastSyncAt, _clock().toIso8601String());
    _store.notify(touched);
    return SyncResult(pages: pages, touched: touched);
  }

  /// Olvida el cursor: la próxima sync baja todo de nuevo.
  Future<void> reset() => _store.setValue(KvKeys.syncCursor, null);
}
