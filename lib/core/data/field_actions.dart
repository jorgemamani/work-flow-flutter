import '../auth/profile.dart';
import '../db/record_store.dart';
import '../ids.dart';
import '../network/api_paths.dart';
import '../outbox/outbox_op.dart';
import '../outbox/outbox_store.dart';
import '../photos/photo_service.dart';
import '../sync/sync_page.dart';
import 'models.dart';

/// Marca de un ítem al recibir un remito (v4 §9.5).
enum ReceptionResult { received, missing, damaged }

class ReceptionLineInput {
  ReceptionLineInput({
    required this.item,
    this.result = ReceptionResult.received,
    this.quantityReceived,
    List<LocalPhoto>? photos,
    this.notes,
  }) : photos = photos ?? [];

  final RemitoItem item;
  ReceptionResult result;
  num? quantityReceived;
  final List<LocalPhoto> photos;
  String? notes;

  String get apiResult => switch (result) {
        ReceptionResult.received => 'RECEIVED',
        ReceptionResult.missing => 'MISSING',
        ReceptionResult.damaged => 'DAMAGED',
      };
}

class VerificationLineInput {
  VerificationLineInput({required this.asset, this.conditionId, this.notes, List<LocalPhoto>? photos})
      : lineId = newId(),
        photos = photos ?? [];

  /// Id del renglón (UUIDv7): las fotos lo usan como `ownerSubItemId`.
  final String lineId;
  final Asset asset;
  String? conditionId;
  String? notes;
  final List<LocalPhoto> photos;
}

class RequirementItemInput {
  RequirementItemInput({this.modelId, this.assetId, this.variant, this.quantity = 1, this.description});

  final String? modelId;
  final String? assetId;
  final String? variant;
  final num quantity;
  final String? description;

  Json toJson() => {
        if (modelId != null) 'modelId': modelId,
        if (assetId != null) 'assetId': assetId,
        if (variant != null && variant!.isNotEmpty) 'variant': variant,
        'quantity': quantity,
        if (description != null && description!.isNotEmpty) 'description': description,
      };
}

/// Datos de un ítem nuevo (alta desde el celular, D-18 / contrato §4).
class AssetDraft {
  AssetDraft({
    required this.model,
    required this.internalCode,
    required this.holderType,
    required this.holderId,
    this.effectiveLocationId,
    this.effectiveProjectId,
    this.manufacturerBarcode,
    this.serialNumber,
    this.conditionId,
    this.description,
    this.notes,
    this.licensePlate,
    this.chassisNumber,
    this.engineNumber,
    this.year,
    this.custodianEmployeeId,
  });

  final AssetModel model;
  final String internalCode;

  /// Portador inicial: LOCATION, ASSET (contenedor/vehículo) o EMPLOYEE.
  final String holderType;
  final String holderId;

  /// Dónde queda realmente (para mostrarlo antes de sincronizar).
  final String? effectiveLocationId;
  final String? effectiveProjectId;
  final String? manufacturerBarcode;
  final String? serialNumber;
  final String? conditionId;
  final String? description;
  final String? notes;
  final String? licensePlate;
  final String? chassisNumber;
  final String? engineNumber;
  final int? year;
  final String? custodianEmployeeId;

  static String? _clean(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

  /// Body de `PUT /inventory/assets/:id` (sin `occurredAt`).
  Json toBody() => {
        'modelId': model.id,
        'internalCode': internalCode.trim(),
        'initialHolder': {'type': holderType, 'id': holderId},
        if (_clean(manufacturerBarcode) != null) 'manufacturerBarcode': _clean(manufacturerBarcode),
        if (_clean(serialNumber) != null) 'serialNumber': _clean(serialNumber),
        if (conditionId != null) 'conditionId': conditionId,
        if (_clean(description) != null) 'description': _clean(description),
        if (_clean(notes) != null) 'notes': _clean(notes),
        if (model.isVehicle) ...{
          if (_clean(licensePlate) != null) 'licensePlate': _clean(licensePlate),
          if (_clean(chassisNumber) != null) 'chassisNumber': _clean(chassisNumber),
          if (_clean(engineNumber) != null) 'engineNumber': _clean(engineNumber),
          if (year != null) 'year': year,
        },
        if (model.requiresCustody && custodianEmployeeId != null) 'custodianEmployeeId': custodianEmployeeId,
      };
}

class ReturnLineInput {
  const ReturnLineInput({this.assetId, this.modelId, this.variant, this.quantity});

  final String? assetId;
  final String? modelId;
  final String? variant;
  final num? quantity;

  Json toJson() => {
        if (assetId != null) 'assetId': assetId,
        if (modelId != null) 'modelId': modelId,
        if (variant != null && variant!.isNotEmpty) 'variant': variant,
        if (quantity != null) 'quantity': quantity,
      };
}

/// Todo lo que se registra en campo: arma el hecho con id UUIDv7 y
/// `occurredAt` del teléfono, lo encola junto con sus fotos y aplica el
/// cambio optimista en la base local (contrato §4 y §5).
class FieldActions {
  FieldActions({
    required OutboxStore outbox,
    required void Function() onEnqueued,
    DateTime Function()? clock,
  })  : _outbox = outbox,
        _onEnqueued = onEnqueued,
        _clock = clock ?? DateTime.now;

  final OutboxStore _outbox;
  final void Function() _onEnqueued;
  final DateTime Function() _clock;

  Future<void> _enqueue(List<OutboxOp> ops) async {
    await _outbox.enqueue(ops);
    _onEnqueued();
  }

  OutboxOp _put(
    String id,
    String path,
    Json body,
    OutboxLabel label, {
    List<RecordPatch> patches = const [],
  }) =>
      OutboxOp(
        id: id,
        kind: OutboxKind.request,
        method: 'PUT',
        path: path,
        body: body,
        label: label,
        occurredAt: DateTime.parse(body['occurredAt'] as String),
        patches: patches,
      );

  OutboxOp _photo(
    LocalPhoto photo, {
    required String ownerType,
    required String ownerId,
    required String parentId,
    String? ownerSubItemId,
    String? assetId,
    required String what,
  }) =>
      OutboxOp(
        id: photo.id,
        kind: OutboxKind.attachment,
        method: 'PUT',
        path: ApiPaths.attachment(photo.id),
        body: {
          'ownerType': ownerType,
          'ownerId': ownerId,
          if (ownerSubItemId != null) 'ownerSubItemId': ownerSubItemId,
          if (assetId != null) 'assetId': assetId,
          'mimeType': LocalPhoto.mimeType,
          'sizeBytes': photo.sizeBytes,
          'takenAt': nowIso(photo.takenAt),
        },
        label: OutboxLabel('opPhoto', {'what': what}),
        occurredAt: photo.takenAt,
        parentId: parentId,
        filePath: photo.path,
      );

  // ── Ítems ──────────────────────────────────────────────────────────────────

  /// Alta de un ítem sin señal (D-18): `PUT /inventory/assets/:id` con id del
  /// teléfono. El ítem aparece enseguida en la base local (y se puede mover o
  /// verificar: esos hechos van después en la cola). Las fotos se encolan
  /// detrás del alta con `ownerType: ASSET`.
  ///
  /// La primera foto la adopta la API como foto vigente al confirmarla (el
  /// ítem no tiene otra); el teléfono la muestra así desde ya.
  Future<String> createAsset(AssetDraft draft, {List<LocalPhoto> photos = const []}) async {
    final id = newId();
    final at = nowIso(_clock());
    final body = {...draft.toBody(), 'occurredAt': at};
    final current = photos.isEmpty ? null : photos.first;
    await _enqueue([
      _put(
        id,
        ApiPaths.asset(id),
        body,
        OutboxLabel('opCreateAsset', {'code': draft.internalCode.trim()}),
        patches: [
          createAssetPatch(id, draft, at),
          if (current != null)
            RecordPatch(source: SyncSources.assets, id: id, fields: {'currentPhotoId': current.id}),
        ],
      ),
      for (final p in photos)
        _photo(
          p,
          ownerType: 'ASSET',
          ownerId: id,
          assetId: id,
          parentId: id,
          what: draft.internalCode.trim(),
        ),
    ]);
    return id;
  }

  /// La fila que ve el teléfono hasta que la API devuelva la verdadera.
  static RecordPatch createAssetPatch(String id, AssetDraft d, String at) {
    final body = d.toBody();
    body.remove('initialHolder');
    return RecordPatch(source: SyncSources.assets, id: id, fields: {
      ...body,
      '_local': true,
      'status': 'OPERATIONAL',
      'holderType': d.holderType,
      'holderId': d.holderId,
      'effectiveLocationId': d.effectiveLocationId,
      'effectiveProjectId': d.effectiveProjectId,
      'custodianEmployeeId': d.custodianEmployeeId,
      'openRemitoId': null,
      'currentPhotoId': null,
      'locationUpdatedAt': at,
      'createdAt': at,
    });
  }

  /// Después de un 409 ("el código ya existe"): corrige el código interno del
  /// alta fallida y la vuelve a la cola con el mismo id (y sus fotos).
  static (Json, List<RecordPatch>, OutboxLabel) withNewInternalCode(OutboxOp op, String code) {
    final body = {...?op.body, 'internalCode': code.trim()};
    final patches = [
      for (final p in op.patches)
        p.source == SyncSources.assets && p.id == op.id
            ? RecordPatch(source: p.source, id: p.id, fields: {...p.fields, 'internalCode': code.trim()})
            : p,
    ];
    return (body, patches, OutboxLabel('opCreateAsset', {'code': code.trim()}));
  }

  /// Mover un ítem dentro del proyecto (RN-02): a una ubicación, a un
  /// contenedor/vehículo (D17) o a mi cargo.
  Future<void> moveAsset({
    required Asset asset,
    required String toHolderType,
    required String toHolderId,
    String? effectiveLocationId,
    String? notes,
  }) async {
    final id = newId();
    final at = nowIso(_clock());
    await _enqueue([
      _put(
        id,
        ApiPaths.assetMovement(id),
        {
          'occurredAt': at,
          'assetId': asset.id,
          'toHolderType': toHolderType,
          'toHolderId': toHolderId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        OutboxLabel('opMove', {'code': asset.internalCode}),
        patches: [
          RecordPatch(source: SyncSources.assets, id: asset.id, fields: {
            '_pending': true,
            'holderType': toHolderType,
            'holderId': toHolderId,
            'effectiveLocationId': effectiveLocationId,
            'locationUpdatedAt': at,
          }),
        ],
      ),
    ]);
  }

  Future<void> changeStatus({
    required Asset asset,
    String? toStatus,
    String? toConditionId,
    String? reason,
  }) async {
    final id = newId();
    await _enqueue([
      _put(
        id,
        ApiPaths.assetStatusChange(id),
        {
          'occurredAt': nowIso(_clock()),
          'assetId': asset.id,
          if (toStatus != null) 'toStatus': toStatus,
          if (toConditionId != null) 'toConditionId': toConditionId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
        OutboxLabel('opStatus', {'code': asset.internalCode}),
        patches: [
          RecordPatch(source: SyncSources.assets, id: asset.id, fields: {
            '_pending': true,
            if (toStatus != null) 'status': toStatus,
            if (toConditionId != null) 'conditionId': toConditionId,
          }),
        ],
      ),
    ]);
  }

  // ── Remitos ────────────────────────────────────────────────────────────────

  /// Confirmar la recepción ítem por ítem (LOG-07, RN-20). Las fotos de los
  /// dañados se encolan después del hecho (contrato §5).
  Future<void> receiveRemito({
    required Remito remito,
    required List<ReceptionLineInput> lines,
    String? notes,
  }) async {
    final id = newId();
    final at = nowIso(_clock());
    final withDiff = lines.any((l) =>
        l.result != ReceptionResult.received ||
        (l.quantityReceived != null && l.quantityReceived! < l.item.quantitySent));
    final patches = <RecordPatch>[
      RecordPatch(source: SyncSources.remitos, id: remito.id, fields: {
        '_pending': true,
        'status': withDiff ? 'RECEIVED_WITH_DIFFERENCES' : 'RECEIVED',
        'receivedAt': at,
      }),
      for (final l in lines) ...[
        RecordPatch(source: SyncSources.remitoItems, id: l.item.id, fields: {
          'result': l.apiResult,
          if (l.quantityReceived != null) 'quantityReceived': l.quantityReceived,
        }),
        if (l.item.assetId != null && l.result != ReceptionResult.missing)
          RecordPatch(source: SyncSources.assets, id: l.item.assetId!, fields: {
            '_pending': true,
            'holderType': HolderTypes.location,
            'holderId': remito.destinationId,
            'effectiveLocationId': remito.destinationId,
            'effectiveProjectId': remito.destinationProjectId,
            'openRemitoId': null,
            'locationUpdatedAt': at,
            if (l.result == ReceptionResult.damaged) 'status': 'DAMAGED',
          }),
      ],
    ];
    await _enqueue([
      _put(
        id,
        ApiPaths.remitoReception(id),
        {
          'occurredAt': at,
          'remitoId': remito.id,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'lines': [
            for (final l in lines)
              {
                'remitoItemId': l.item.id,
                'result': l.apiResult,
                if (l.quantityReceived != null) 'quantityReceived': l.quantityReceived,
                if (l.photos.isNotEmpty) 'attachmentIds': [for (final p in l.photos) p.id],
                if (l.notes != null && l.notes!.isNotEmpty) 'notes': l.notes,
              },
          ],
        },
        OutboxLabel('opReception', {'number': remito.displayNumber}),
        patches: patches,
      ),
      for (final l in lines)
        for (final p in l.photos)
          _photo(
            p,
            ownerType: 'REMITO',
            ownerId: remito.id,
            ownerSubItemId: l.item.id,
            assetId: l.item.assetId,
            parentId: id,
            what: remito.displayNumber,
          ),
    ]);
  }

  /// Remito de devolución armado sin señal (v4 §9.4): POST idempotente con id
  /// del cliente y después `submit`.
  Future<void> returnRemito({
    required String originLocationId,
    required String destinationLocationId,
    required String? projectId,
    required List<ReturnLineInput> lines,
    String? notes,
  }) async {
    final id = newId();
    final now = _clock();
    await _enqueue([
      OutboxOp(
        id: id,
        kind: OutboxKind.request,
        method: 'POST',
        path: ApiPaths.remitos,
        body: {
          'id': id,
          'type': 'RETURN',
          'originLocationId': originLocationId,
          'destinationType': 'LOCATION',
          'destinationId': destinationLocationId,
          'items': [for (final l in lines) l.toJson()],
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        label: const OutboxLabel('opReturn'),
        occurredAt: now,
        patches: [
          RecordPatch(source: SyncSources.remitos, id: id, fields: {
            '_local': true,
            'type': 'RETURN',
            'status': 'DRAFT',
            'originType': 'LOCATION',
            'originId': originLocationId,
            'originProjectId': projectId,
            'destinationType': 'LOCATION',
            'destinationId': destinationLocationId,
            'createdAt': nowIso(now),
          }),
          for (final l in lines)
            if (l.assetId != null)
              RecordPatch(source: SyncSources.assets, id: l.assetId!, fields: {'openRemitoId': id}),
        ],
      ),
      OutboxOp(
        id: '$id-submit',
        kind: OutboxKind.request,
        method: 'POST',
        path: ApiPaths.remitoSubmit(id),
        label: const OutboxLabel('opReturnSubmit'),
        occurredAt: now,
        parentId: id,
      ),
    ]);
  }

  // ── Evidencia ──────────────────────────────────────────────────────────────

  /// Verificación con fotos (REP-03): un renglón por ítem, las fotos
  /// declaradas en `photoIds` y subidas después con `ownerSubItemId`.
  Future<void> submitVerification({
    required String projectId,
    String? scheduleId,
    required List<VerificationLineInput> lines,
    String? notes,
  }) async {
    final id = newId();
    final at = nowIso(_clock());
    await _enqueue([
      _put(
        id,
        ApiPaths.verification(id),
        {
          'occurredAt': at,
          'projectId': projectId,
          if (scheduleId != null) 'verificationScheduleId': scheduleId,
          if (notes != null && notes.isNotEmpty) 'payload': {'notes': notes},
          'lines': [
            for (final l in lines)
              {
                'id': l.lineId,
                'assetId': l.asset.id,
                if (l.conditionId != null) 'reportedConditionId': l.conditionId,
                if (l.notes != null && l.notes!.isNotEmpty) 'notes': l.notes,
                'photoIds': [for (final p in l.photos) p.id],
              },
          ],
        },
        OutboxLabel('opVerification', {'count': '${lines.length}'}),
        patches: [
          RecordPatch(source: SyncSources.submissions, id: id, fields: {
            '_local': true,
            'type': 'VERIFICATION',
            'projectId': projectId,
            'occurredAt': at,
            'payload': {'notes': notes ?? '', '_lines': lines.length},
          }),
        ],
      ),
      for (final l in lines)
        for (final p in l.photos)
          _photo(
            p,
            ownerType: 'SUBMISSION',
            ownerId: id,
            ownerSubItemId: l.lineId,
            assetId: l.asset.id,
            parentId: id,
            what: l.asset.internalCode,
          ),
    ]);
  }

  /// Bitácora diaria (REP-01).
  /// [equipmentOk]: cómo están las herramientas y vehículos; [news], las
  /// novedades. Las fotos son opcionales.
  Future<void> submitDailyLog({
    required String projectId,
    required String notes,
    List<String> tasks = const [],
    bool? equipmentOk,
    String? news,
    List<LocalPhoto> photos = const [],
  }) async {
    final id = newId();
    final at = nowIso(_clock());
    final cleanNews = news?.trim() ?? '';
    final payload = {
      'notes': notes,
      if (tasks.isNotEmpty) 'tasks': tasks,
      if (equipmentOk != null) 'equipmentOk': equipmentOk,
      if (cleanNews.isNotEmpty) 'news': cleanNews,
    };
    await _enqueue([
      _put(
        id,
        ApiPaths.submission(id),
        {
          'occurredAt': at,
          'projectId': projectId,
          'type': 'DAILY_LOG',
          'direction': 'EMPLOYEE_TO_COMPANY',
          'payload': payload,
        },
        const OutboxLabel('opDailyLog'),
        patches: [
          RecordPatch(source: SyncSources.submissions, id: id, fields: {
            '_local': true,
            'type': 'DAILY_LOG',
            'direction': 'EMPLOYEE_TO_COMPANY',
            'projectId': projectId,
            'occurredAt': at,
            'payload': payload,
          }),
        ],
      ),
      for (final p in photos)
        _photo(p, ownerType: 'SUBMISSION', ownerId: id, parentId: id, what: at.substring(0, 10)),
    ]);
  }

  /// Incidencia (REP-05) con fotos opcionales.
  Future<void> submitIncident({
    required String projectId,
    required String kind,
    String? severity,
    required String title,
    String? description,
    String? assetId,
    List<LocalPhoto> photos = const [],
  }) async {
    final id = newId();
    final at = nowIso(_clock());
    await _enqueue([
      _put(
        id,
        ApiPaths.incident(id),
        {
          'occurredAt': at,
          'projectId': projectId,
          'kind': kind,
          if (severity != null) 'severity': severity,
          'title': title,
          'payload': {'notes': description ?? ''},
          if (assetId != null) 'assetId': assetId,
        },
        OutboxLabel('opIncident', {'title': title}),
        patches: [
          RecordPatch(source: SyncSources.submissions, id: id, fields: {
            '_local': true,
            'type': 'INCIDENT',
            'projectId': projectId,
            'title': title,
            'occurredAt': at,
            'assetId': assetId,
            'payload': {'notes': description ?? '', '_kind': kind, '_severity': severity},
          }),
        ],
      ),
      for (final p in photos)
        _photo(p, ownerType: 'SUBMISSION', ownerId: id, assetId: assetId, parentId: id, what: title),
    ]);
  }

  /// Solicitud de ítems nuevos, bajas o reparación (REP-04 / D19).
  Future<void> submitRequirement({
    required String projectId,
    required String kind,
    required List<RequirementItemInput> items,
    String? notes,
    String? neededBy,
  }) async {
    final id = newId();
    final at = nowIso(_clock());
    await _enqueue([
      _put(
        id,
        ApiPaths.requirement(id),
        {
          'occurredAt': at,
          'kind': kind,
          'projectId': projectId,
          if (neededBy != null) 'neededBy': neededBy,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'items': [for (final i in items) i.toJson()],
        },
        OutboxLabel('opRequirement', {'count': '${items.length}'}),
        patches: [
          RecordPatch(source: SyncSources.requirements, id: id, fields: {
            '_local': true,
            'kind': kind,
            'status': 'PENDING',
            'projectId': projectId,
            'requestedAt': at,
            'notes': notes,
            '_items': items.length,
          }),
        ],
      ),
    ]);
  }

  /// Subida o bajada (PER-03). Sin [employeeId] es la propia; la de otro
  /// requiere `checkins.write_others` (RN-13).
  Future<void> checkIn({
    required String projectId,
    required String type,
    required String employeeId,
    required bool self,
    required String employeeName,
    String? notes,
  }) async {
    final id = newId();
    final at = nowIso(_clock());
    await _enqueue([
      _put(
        id,
        ApiPaths.checkIn(id),
        {
          'occurredAt': at,
          'projectId': projectId,
          'type': type,
          if (!self) 'employeeId': employeeId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        OutboxLabel(type == 'UP' ? 'opCheckInUp' : 'opCheckInDown', {'name': employeeName}),
        patches: [
          RecordPatch(source: SyncSources.checkIns, id: id, fields: {
            '_local': true,
            'employeeId': employeeId,
            'projectId': projectId,
            'type': type,
            'occurredAt': at,
          }),
          if (!self)
            RecordPatch(source: SyncSources.employees, id: employeeId, fields: {
              'onSite': type == 'UP',
              'currentProjectId': type == 'UP' ? projectId : null,
            }),
        ],
      ),
    ]);
  }
}

/// Estado de empleado optimista después de una marcación propia.
Profile applySelfCheckIn(Profile p, {required String type, required String projectId}) =>
    type == 'UP'
        ? p.withEmployee(onSite: true, currentProjectId: projectId)
        : p.withEmployee(onSite: false);
