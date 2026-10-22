import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/profile.dart';
import '../../../core/auth/profile_repository.dart';
import '../../../core/auth/session_manager.dart';
import '../../../core/data/field_repository.dart';
import '../../../core/db/local_database.dart';
import '../../../core/db/record_store.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/outbox/outbox_processor.dart';
import '../../../core/outbox/outbox_store.dart';
import '../../../core/sync/sync_coordinator.dart';

enum SessionPhase { unknown, unauthenticated, choosingTenant, authenticated }

class SessionState extends Equatable {
  const SessionState({
    this.phase = SessionPhase.unknown,
    this.profile,
    this.projectId,
    this.memberships = const [],
    this.busy = false,
    this.error,
    this.expired = false,
  });

  final SessionPhase phase;
  final Profile? profile;

  /// Proyecto actual (la mina donde trabaja).
  final String? projectId;
  final List<Membership> memberships;
  final bool busy;

  /// Mensaje de la API o clave de error conocida ('offline').
  final String? error;

  /// La sesión venció (refresh rechazado): volver a ingresar sin perder la cola.
  final bool expired;

  SessionState copyWith({
    SessionPhase? phase,
    Profile? profile,
    String? projectId,
    List<Membership>? memberships,
    bool? busy,
    String? error,
    bool clearError = false,
    bool? expired,
  }) =>
      SessionState(
        phase: phase ?? this.phase,
        profile: profile ?? this.profile,
        projectId: projectId ?? this.projectId,
        memberships: memberships ?? this.memberships,
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
        expired: expired ?? this.expired,
      );

  @override
  List<Object?> get props =>
      [phase, profile?.raw, projectId, memberships.length, busy, error, expired];
}

/// Quién está usando la app y en qué proyecto. Abre sin señal con el perfil
/// guardado (RN-28): solo vuelve al login si la API rechaza el refresh.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required SessionManager session,
    required ProfileRepository profiles,
    required LocalDatabase local,
    required RecordStore records,
    required OutboxStore outbox,
    required SyncCoordinator coordinator,
    required FieldRepository repo,
  })  : _session = session,
        _profiles = profiles,
        _local = local,
        _records = records,
        _outbox = outbox,
        _coordinator = coordinator,
        _repo = repo,
        super(const SessionState());

  final SessionManager _session;
  final ProfileRepository _profiles;
  final LocalDatabase _local;
  final RecordStore _records;
  final OutboxStore _outbox;
  final SyncCoordinator _coordinator;
  final FieldRepository _repo;
  final _subs = <StreamSubscription<dynamic>>[];

  Future<void> start() async {
    _subs
      ..add(_session.onExpired.listen((_) => _expire()))
      ..add(_profiles.changes.listen((p) async {
        if (p != null && state.phase == SessionPhase.authenticated) {
          emit(state.copyWith(profile: p, projectId: await _resolveProject(p)));
        }
      }))
      ..add(_repo.changes.listen((sources) {
        if (sources.contains('projects') || sources.contains('assignments')) {
          unawaited(reresolveProject());
        }
      }))
      ..add(_coordinator.stream.listen((s) {
        if (s.sessionExpired && !state.expired) _expire();
      }));

    final profile = await _profiles.loadCached();
    if (profile != null && await _session.hasSession()) {
      emit(SessionState(
        phase: SessionPhase.authenticated,
        profile: profile,
        projectId: await _resolveProject(profile),
      ));
      unawaited(_coordinator.syncNow());
    } else {
      emit(const SessionState(phase: SessionPhase.unauthenticated));
    }
  }

  void _expire() {
    emit(SessionState(
      phase: SessionPhase.unauthenticated,
      profile: state.profile,
      expired: true,
    ));
  }

  Future<void> loginField({
    required String cuit,
    required String documentNumber,
    required String pin,
  }) =>
      _login(() => _session.loginField(cuit: cuit, documentNumber: documentNumber, pin: pin));

  Future<void> loginOffice({
    required String email,
    required String password,
    String? cuit,
  }) =>
      _login(() => _session.loginOffice(email: email, password: password, cuit: cuit));

  Future<void> _login(Future<List<Membership>> Function() call) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final memberships = await call();
      final profile = await _profiles.fetch();
      await _adopt(profile);
      if (memberships.length > 1) {
        emit(state.copyWith(
          phase: SessionPhase.choosingTenant,
          memberships: memberships,
          busy: false,
        ));
        return;
      }
      await _enter(profile);
    } on OfflineException {
      emit(state.copyWith(busy: false, error: 'offline'));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, error: e.message));
    }
  }

  /// Si el perfil es de otra persona o empresa, los datos locales no sirven.
  /// La cola se conserva solo si es del mismo dueño (volver a ingresar tras
  /// una sesión vencida no pierde lo registrado sin señal).
  Future<void> _adopt(Profile profile) async {
    final owner = await _records.getValue(KvKeys.ownerKey);
    if (owner != null && owner != profile.ownerKey) {
      await _local.wipe();
    }
    await _records.setValue(KvKeys.ownerKey, profile.ownerKey);
    await _profiles.save(profile);
  }

  Future<void> _enter(Profile profile) async {
    _coordinator.sessionRestored();
    emit(SessionState(
      phase: SessionPhase.authenticated,
      profile: profile,
      projectId: await _resolveProject(profile),
    ));
    unawaited(_coordinator.syncNow());
  }

  /// Cambio de empresa (contrato §2): tokens nuevos y datos locales nuevos.
  /// Con acciones sin enviar no se permite (se mandarían a la otra empresa).
  Future<bool> switchTenant(String tenantId) async {
    final counts = await _outbox.currentCounts();
    if (counts.pending > 0) {
      emit(state.copyWith(error: 'pendingBlocksSwitch'));
      return false;
    }
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _session.switchTenant(tenantId);
      final profile = await _profiles.fetch();
      await _adopt(profile);
      await _enter(profile);
      return true;
    } on OfflineException {
      emit(state.copyWith(busy: false, error: 'offline'));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, error: e.message));
    }
    return false;
  }

  Future<void> chooseTenant(String tenantId) async {
    if (tenantId == state.profile?.tenantId) {
      await _enter(state.profile!);
      return;
    }
    await switchTenant(tenantId);
  }

  Future<void> selectProject(String projectId) async {
    await _records.setValue(KvKeys.selectedProjectId, projectId);
    emit(state.copyWith(projectId: projectId));
    unawaited(_coordinator.syncNow());
  }

  /// Marcación propia: el estado cambia ya, aunque no haya señal.
  Future<void> applyLocalProfile(Profile p) => _profiles.save(p);

  Future<void> logout() async {
    await _session.logout();
    await _local.wipe();
    await _profiles.save(null);
    emit(const SessionState(phase: SessionPhase.unauthenticated));
  }

  void clearError() => emit(state.copyWith(clearError: true));

  /// Elegido > donde está arriba > asignado > primero que tenga.
  Future<String?> _resolveProject(Profile p) async {
    final projects = await _repo.projects();
    final ids = {for (final pr in projects) pr.id};
    final selected = await _records.getValue(KvKeys.selectedProjectId);
    if (selected != null && (ids.isEmpty || ids.contains(selected))) return selected;
    if (p.currentProjectId != null) return p.currentProjectId;
    if (p.employeeId != null) {
      final assigned = await _repo.assignedProjectIds(p.employeeId!);
      if (assigned.isNotEmpty) return assigned.first;
    }
    return projects.isEmpty ? null : projects.first.id;
  }

  /// Después de la primera sync puede aparecer el proyecto.
  Future<void> reresolveProject() async {
    final p = state.profile;
    if (p == null || state.phase != SessionPhase.authenticated) return;
    final id = await _resolveProject(p);
    if (id != state.projectId) emit(state.copyWith(projectId: id));
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
