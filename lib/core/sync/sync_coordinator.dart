import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/profile_repository.dart';
import '../db/record_store.dart';
import '../errors/app_exception.dart';
import '../network/connectivity_service.dart';
import '../outbox/outbox_processor.dart';
import '../outbox/outbox_store.dart';
import 'sync_engine.dart';

class SyncStatus extends Equatable {
  const SyncStatus({
    this.online = true,
    this.simulatedOffline = false,
    this.syncing = false,
    this.lastSyncAt,
    this.counts = const OutboxCounts(),
    this.sessionExpired = false,
    this.lastError,
  });

  final bool online;
  final bool simulatedOffline;
  final bool syncing;
  final DateTime? lastSyncAt;
  final OutboxCounts counts;

  /// La API rechazó el refresh: hay que volver a ingresar (la cola se guarda).
  final bool sessionExpired;
  final String? lastError;

  SyncStatus copyWith({
    bool? online,
    bool? simulatedOffline,
    bool? syncing,
    DateTime? lastSyncAt,
    OutboxCounts? counts,
    bool? sessionExpired,
    String? lastError,
    bool clearError = false,
  }) =>
      SyncStatus(
        online: online ?? this.online,
        simulatedOffline: simulatedOffline ?? this.simulatedOffline,
        syncing: syncing ?? this.syncing,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        counts: counts ?? this.counts,
        sessionExpired: sessionExpired ?? this.sessionExpired,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  @override
  List<Object?> get props =>
      [online, simulatedOffline, syncing, lastSyncAt, counts, sessionExpired, lastError];
}

/// Orquesta la sincronización: refresh → drenar la cola → bajar cambios →
/// perfil. Se dispara al recuperar señal, al volver a la app, al encolar y
/// cada pocos minutos mientras haya pendientes.
class SyncCoordinator extends Cubit<SyncStatus> {
  SyncCoordinator({
    required ConnectivityService connectivity,
    required OutboxStore outbox,
    required OutboxProcessor processor,
    required SyncEngine engine,
    required RecordStore store,
    required ProfileRepository profiles,
    Future<void> Function()? afterPull,
  })  : _connectivity = connectivity,
        _outbox = outbox,
        _processor = processor,
        _engine = engine,
        _store = store,
        _profiles = profiles,
        _afterPull = afterPull,
        super(const SyncStatus());

  final ConnectivityService _connectivity;
  final OutboxStore _outbox;
  final OutboxProcessor _processor;
  final SyncEngine _engine;
  final RecordStore _store;
  final ProfileRepository _profiles;

  /// Descarga previa de fotos vigentes, etc.
  final Future<void> Function()? _afterPull;

  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _timer;
  Future<void>? _running;

  static const retryEvery = Duration(minutes: 2);

  Future<void> start() async {
    final last = await _store.getValue(KvKeys.lastSyncAt);
    emit(state.copyWith(
      online: _connectivity.isOnline,
      simulatedOffline: _connectivity.simulatedOffline,
      lastSyncAt: last == null ? null : DateTime.tryParse(last),
      counts: await _outbox.currentCounts(),
    ));
    _subs
      ..add(_connectivity.onlineChanges.listen((online) {
        emit(state.copyWith(online: online, simulatedOffline: _connectivity.simulatedOffline));
        if (online) unawaited(syncNow());
      }))
      ..add(_outbox.counts.listen((c) => emit(state.copyWith(counts: c))));
    _timer = Timer.periodic(retryEvery, (_) {
      if (state.counts.pending > 0) unawaited(syncNow());
    });
  }

  /// Hay algo nuevo en la cola: intentar mandarlo ya si hay señal.
  void kick() {
    if (_connectivity.isOnline) unawaited(syncNow());
  }

  Future<void> setSimulatedOffline(bool value) async {
    await _store.setValue(KvKeys.simulateOffline, value ? '1' : null);
    _connectivity.setSimulatedOffline(value);
    emit(state.copyWith(online: _connectivity.isOnline, simulatedOffline: value));
  }

  /// Un solo ciclo a la vez.
  Future<void> syncNow() {
    final running = _running;
    if (running != null) return running;
    final run = _cycle().whenComplete(() => _running = null);
    _running = run;
    return run;
  }

  Future<void> _cycle() async {
    if (!_connectivity.isOnline || state.sessionExpired) return;
    emit(state.copyWith(syncing: true, clearError: true));
    try {
      final report = await _processor.drain();
      if (report.stop == DrainStop.sessionExpired) {
        emit(state.copyWith(syncing: false, sessionExpired: true));
        return;
      }
      if (report.stop == DrainStop.offline) {
        emit(state.copyWith(syncing: false, lastError: 'offline'));
        return;
      }
      // Un rechazo deja cambios optimistas que la API no aceptó: bajar todo de
      // nuevo los revierte (y borra lo creado localmente que no llegó).
      if (report.failed > 0) await _engine.reset();
      await _engine.pull();
      try {
        await _profiles.fetch();
      } on ApiException {
        // El perfil se reintenta en la próxima vuelta.
      }
      await _afterPull?.call();
      final last = await _store.getValue(KvKeys.lastSyncAt);
      emit(state.copyWith(
        syncing: false,
        lastSyncAt: last == null ? null : DateTime.tryParse(last),
        counts: await _outbox.currentCounts(),
      ));
    } on OfflineException {
      emit(state.copyWith(syncing: false, lastError: 'offline'));
    } on SessionExpiredException {
      emit(state.copyWith(syncing: false, sessionExpired: true));
    } on ApiException catch (e) {
      emit(state.copyWith(syncing: false, lastError: e.message));
    } catch (e) {
      emit(state.copyWith(syncing: false, lastError: e.toString()));
    }
  }

  /// Después de volver a ingresar.
  void sessionRestored() => emit(state.copyWith(sessionExpired: false));

  Future<void> refreshCounts() async =>
      emit(state.copyWith(counts: await _outbox.currentCounts()));

  @override
  Future<void> close() async {
    _timer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
