import '../db/record_store.dart';
import '../sync/sync_page.dart';
import 'models.dart';

/// Datos que muestra la app de campo, leídos SIEMPRE de la base local.
class FieldRepository {
  FieldRepository(this._store);

  final RecordStore _store;

  Stream<Set<String>> get changes => _store.changes;

  Future<List<T>> _all<T>(String source, T Function(Json) f, {String? projectId}) async =>
      [for (final r in await _store.all(source, projectId: projectId)) f(r)];

  Future<T?> _one<T>(String source, String? id, T Function(Json) f) async {
    if (id == null) return null;
    final r = await _store.get(source, id);
    return r == null ? null : f(r);
  }

  // ── Catálogos ──────────────────────────────────────────────────────────────

  Future<List<Project>> projects() async =>
      (await _all(SyncSources.projects, Project.new))
        ..sort((a, b) => a.name.compareTo(b.name));

  Future<Project?> project(String? id) => _one(SyncSources.projects, id, Project.new);

  Future<Map<String, Location>> locations() async => {
        for (final l in await _all(SyncSources.locations, Location.new)) l.id: l,
      };

  Future<Map<String, AssetModel>> models() async => {
        for (final m in await _all(SyncSources.assetModels, AssetModel.new)) m.id: m,
      };

  Future<Map<String, Brand>> brands() async => {
        for (final b in await _all(SyncSources.brands, Brand.new)) b.id: b,
      };

  Future<List<AssetCondition>> conditions() async =>
      (await _all(SyncSources.assetConditions, AssetCondition.new))
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<Map<String, Employee>> employees() async => {
        for (final e in await _all(SyncSources.employees, Employee.new)) e.id: e,
      };

  // ── Ítems ──────────────────────────────────────────────────────────────────

  Future<Map<String, Asset>> assetsById() async => {
        for (final a in await _all(SyncSources.assets, Asset.new)) a.id: a,
      };

  Future<Asset?> asset(String id) => _one(SyncSources.assets, id, Asset.new);

  /// Ítems del proyecto: los que están efectivamente en él (incluye los que
  /// van dentro de un contenedor o los lleva una persona del proyecto).
  Future<List<Asset>> projectAssets(String projectId) async =>
      _all(SyncSources.assets, Asset.new, projectId: projectId);

  /// Mis ítems a cargo: los que tengo yo (portador) o de los que soy custodio.
  Future<List<Asset>> myAssets(String employeeId) async => [
        for (final a in await _all(SyncSources.assets, Asset.new))
          if ((a.holderType == HolderTypes.employee && a.holderId == employeeId) ||
              a.custodianEmployeeId == employeeId)
            a,
      ];

  Future<Asset?> findByCode(String code) async {
    for (final a in await _all(SyncSources.assets, Asset.new)) {
      if (a.hasCode(code)) return a;
    }
    return null;
  }

  /// ¿Algún ítem local (sincronizado o creado en el teléfono) ya usa este
  /// código interno? La API responde 409 si se repite en la empresa.
  Future<bool> internalCodeInUse(String code, {String? exceptId}) async {
    final c = code.trim().toLowerCase();
    if (c.isEmpty) return false;
    for (final a in await _all(SyncSources.assets, Asset.new)) {
      if (a.id != exceptId && a.internalCode.trim().toLowerCase() == c) return true;
    }
    return false;
  }

  Future<List<StockBalance>> projectStock(String projectId) async => [
        for (final s in await _all(SyncSources.stockBalances, StockBalance.new))
          if (s.effectiveProjectId == projectId && s.quantity > 0) s,
      ];

  // ── Remitos ────────────────────────────────────────────────────────────────

  /// Remitos en tránsito hacia el proyecto (para confirmar la recepción).
  Future<List<Remito>> incomingRemitos(String projectId) async {
    final locs = await locations();
    return [
      for (final r in await _all(SyncSources.remitos, Remito.new))
        if (r.status == 'IN_TRANSIT' &&
            (r.destinationProjectId == projectId ||
                locs[r.destinationId]?.projectId == projectId))
          r,
    ]..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
  }

  Future<List<Remito>> projectRemitos(String projectId) async => [
        for (final r in await _all(SyncSources.remitos, Remito.new))
          if (r.destinationProjectId == projectId || r.originProjectId == projectId) r,
      ];

  Future<Remito?> remito(String id) => _one(SyncSources.remitos, id, Remito.new);

  Future<List<RemitoItem>> remitoItems(String remitoId) async => [
        for (final i in await _all(SyncSources.remitoItems, RemitoItem.new))
          if (i.remitoId == remitoId) i,
      ];

  // ── Evidencia ──────────────────────────────────────────────────────────────

  Future<List<Submission>> submissions({String? type}) async {
    final list = [
      for (final s in await _all(SyncSources.submissions, Submission.new))
        if ((type == null || s.type == type) && !s.isVoided) s,
    ];
    list.sort((a, b) => (b.occurredAt ?? DateTime(0)).compareTo(a.occurredAt ?? DateTime(0)));
    return list;
  }

  /// Informes que la empresa le mandó al empleado (REP-02).
  Future<List<Submission>> receivedReports(String employeeId) async => [
        for (final s in await submissions())
          if (s.direction == 'COMPANY_TO_EMPLOYEE' && s.recipientEmployeeId == employeeId) s,
      ];

  Future<Map<String, IncidentDetail>> incidentDetails() async => {
        for (final d in await _all(SyncSources.incidentDetails, IncidentDetail.new))
          d.submissionId: d,
      };

  Future<List<Requirement>> requirements() async =>
      (await _all(SyncSources.requirements, Requirement.new))
        ..sort((a, b) => (b.requestedAt ?? DateTime(0)).compareTo(a.requestedAt ?? DateTime(0)));

  Future<List<RequirementItem>> requirementItems(String requirementId) async => [
        for (final i in await _all(SyncSources.requirementItems, RequirementItem.new))
          if (i.requirementId == requirementId) i,
      ];

  Future<List<VerificationSchedule>> schedules(String projectId) async => [
        for (final s in await _all(SyncSources.verificationSchedules, VerificationSchedule.new))
          if (s.projectId == null || s.projectId == projectId) s,
      ];

  Future<List<CheckIn>> checkIns(String employeeId) async {
    final list = [
      for (final c in await _all(SyncSources.checkIns, CheckIn.new))
        if (c.employeeId == employeeId && !c.isVoided) c,
    ];
    list.sort((a, b) => (b.occurredAt ?? DateTime(0)).compareTo(a.occurredAt ?? DateTime(0)));
    return list;
  }

  Future<List<String>> assignedProjectIds(String employeeId) async => [
        for (final a in await _store.all(SyncSources.assignments))
          if (a['employeeId'] == employeeId && a['endDate'] == null) a['projectId'] as String,
      ];
}

/// Dónde está un ítem, resuelto con la cadena de portadores (RN-11): un
/// ítem dentro de una caja que está en el obrador → "Obrador › Caja CJ-001".
class HolderResolver {
  HolderResolver({
    required this.assets,
    required this.locations,
    required this.employees,
    required this.models,
  });

  final Map<String, Asset> assets;
  final Map<String, Location> locations;
  final Map<String, Employee> employees;
  final Map<String, AssetModel> models;

  /// Partes del camino, de afuera hacia adentro.
  List<HolderPart> chain(Asset asset) {
    final parts = <HolderPart>[];
    var type = asset.holderType;
    var id = asset.holderId;
    final seen = <String>{};
    while (id != null && seen.add(id)) {
      switch (type) {
        case HolderTypes.asset:
          final parent = assets[id];
          parts.insert(0, HolderPart(type, id, parent == null ? '?' : label(parent)));
          if (parent == null) return parts;
          type = parent.holderType;
          id = parent.holderId;
        case HolderTypes.location:
          final l = locations[id];
          parts.insert(0, HolderPart(type, id, l?.name ?? '?'));
          return parts;
        case HolderTypes.employee:
          parts.insert(0, HolderPart(type, id, employees[id]?.fullName ?? ''));
          return parts;
        default:
          parts.insert(0, HolderPart(HolderTypes.inTransit, id, ''));
          return parts;
      }
    }
    return parts;
  }

  String label(Asset a) {
    final m = models[a.modelId];
    return m == null ? a.internalCode : '${m.name} · ${a.internalCode}';
  }
}

class HolderPart {
  const HolderPart(this.type, this.id, this.name);

  final String type;
  final String id;
  final String name;
}
