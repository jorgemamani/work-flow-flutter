/// Vistas tipadas sobre las filas de sync (el JSON tal cual lo manda la API).
/// Los enums viajan en inglés; los textos están en los .arb.
library;

typedef Json = Map<String, dynamic>;

String? _s(Json j, String k) => j[k] as String?;
DateTime? _d(Json j, String k) => DateTime.tryParse(j[k] as String? ?? '')?.toLocal();
num? _n(Json j, String k) {
  final v = j[k];
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

abstract class Model {
  const Model(this.raw);

  final Json raw;

  String get id => raw['id'] as String;

  /// Creado en el teléfono y todavía no confirmado por la API.
  bool get isLocal => raw['_local'] == true;

  /// Tiene un cambio hecho en el teléfono que todavía no llegó a la API.
  bool get hasPendingChange => isLocal || raw['_pending'] == true;

  @override
  bool operator ==(Object other) =>
      other is Model && other.runtimeType == runtimeType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Project extends Model {
  const Project(super.raw);

  String get name => _s(raw, 'name') ?? '';
  String? get code => _s(raw, 'code');
  String get status => _s(raw, 'status') ?? '';
  String? get rootLocationId => _s(raw, 'rootLocationId');
}

class Location extends Model {
  const Location(super.raw);

  String get name => _s(raw, 'name') ?? '';
  String get type => _s(raw, 'type') ?? 'OTHER';
  String? get projectId => _s(raw, 'projectId');
  String? get parentId => _s(raw, 'parentId');
  bool get isActive => raw['isActive'] as bool? ?? true;
}

class AssetModel extends Model {
  const AssetModel(super.raw);

  String get name => _s(raw, 'name') ?? '';
  String get category => _s(raw, 'category') ?? '';
  String? get brandId => _s(raw, 'brandId');
  bool get isBulk => _s(raw, 'trackingType') == 'BULK';
  bool get isContainer => raw['isContainer'] as bool? ?? false;
  bool get isVehicle => raw['isVehicle'] as bool? ?? false;
  bool get requiresPhoto => raw['requiresPhoto'] as bool? ?? false;
  bool get requiresSerialNumber => raw['requiresSerialNumber'] as bool? ?? false;
  bool get requiresCustody => raw['requiresCustody'] as bool? ?? false;
  String? get unitOfMeasure => _s(raw, 'unitOfMeasure');
  List<String> get variants =>
      [for (final v in raw['variants'] as List? ?? const []) v.toString()];
}

class Brand extends Model {
  const Brand(super.raw);

  String get name => _s(raw, 'name') ?? '';
}

class AssetCondition extends Model {
  const AssetCondition(super.raw);

  String get name => _s(raw, 'name') ?? '';
  int get sortOrder => (_n(raw, 'sortOrder') ?? 0).toInt();
}

abstract final class HolderTypes {
  static const location = 'LOCATION';
  static const asset = 'ASSET';
  static const employee = 'EMPLOYEE';
  static const inTransit = 'IN_TRANSIT';
}

abstract final class AssetStatuses {
  static const all = [
    'OPERATIONAL',
    'RESERVED',
    'IN_REPAIR',
    'DAMAGED',
    'LOST',
    'RETIRED',
  ];
}

class Asset extends Model {
  const Asset(super.raw);

  String get modelId => _s(raw, 'modelId') ?? '';
  String get internalCode => _s(raw, 'internalCode') ?? '';
  String? get manufacturerBarcode => _s(raw, 'manufacturerBarcode');
  String? get serialNumber => _s(raw, 'serialNumber');
  String get status => _s(raw, 'status') ?? 'OPERATIONAL';
  String? get conditionId => _s(raw, 'conditionId');
  String? get description => _s(raw, 'description');
  String? get licensePlate => _s(raw, 'licensePlate');
  String get holderType => _s(raw, 'holderType') ?? HolderTypes.location;
  String? get holderId => _s(raw, 'holderId');
  String? get effectiveLocationId => _s(raw, 'effectiveLocationId');
  String? get effectiveProjectId => _s(raw, 'effectiveProjectId');
  String? get custodianEmployeeId => _s(raw, 'custodianEmployeeId');
  String? get openRemitoId => _s(raw, 'openRemitoId');
  String? get currentPhotoId => _s(raw, 'currentPhotoId');
  DateTime? get locationUpdatedAt => _d(raw, 'locationUpdatedAt');

  /// Coincide con el texto de búsqueda o con un código escaneado.
  bool matches(String q, {AssetModel? model}) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return true;
    return internalCode.toLowerCase().contains(t) ||
        (manufacturerBarcode?.toLowerCase().contains(t) ?? false) ||
        (serialNumber?.toLowerCase().contains(t) ?? false) ||
        (licensePlate?.toLowerCase().contains(t) ?? false) ||
        (model?.name.toLowerCase().contains(t) ?? false);
  }

  bool hasCode(String code) {
    final c = code.trim();
    return internalCode == c || manufacturerBarcode == c || serialNumber == c;
  }
}

class StockBalance extends Model {
  const StockBalance(super.raw);

  String get modelId => _s(raw, 'modelId') ?? '';
  String get variant => _s(raw, 'variant') ?? '';
  String get holderType => _s(raw, 'holderType') ?? '';
  String? get holderId => _s(raw, 'holderId');
  num get quantity => _n(raw, 'quantity') ?? 0;
  String? get effectiveProjectId => _s(raw, 'effectiveProjectId');
}

class Remito extends Model {
  const Remito(super.raw);

  int? get number => _n(raw, 'number')?.toInt();
  String get type => _s(raw, 'type') ?? '';
  String get status => _s(raw, 'status') ?? '';
  String get originType => _s(raw, 'originType') ?? '';
  String? get originId => _s(raw, 'originId');
  String get destinationType => _s(raw, 'destinationType') ?? '';
  String? get destinationId => _s(raw, 'destinationId');
  String? get originProjectId => _s(raw, 'originProjectId');
  String? get destinationProjectId => _s(raw, 'destinationProjectId');
  DateTime? get dispatchedAt => _d(raw, 'dispatchedAt');
  String? get notes => _s(raw, 'notes');

  String get displayNumber => number == null ? '—' : 'N° $number';
}

class RemitoItem extends Model {
  const RemitoItem(super.raw);

  String get remitoId => _s(raw, 'remitoId') ?? '';
  String? get assetId => _s(raw, 'assetId');
  String? get modelId => _s(raw, 'modelId');
  String get variant => _s(raw, 'variant') ?? '';
  num get quantitySent => _n(raw, 'quantitySent') ?? 1;
  String get result => _s(raw, 'result') ?? 'PENDING';
}

class Employee extends Model {
  const Employee(super.raw);

  String get firstName => _s(raw, 'firstName') ?? '';
  String get lastName => _s(raw, 'lastName') ?? '';
  String get fullName => '$firstName $lastName'.trim();
  String? get documentNumber => _s(raw, 'documentNumber');
  String? get currentProjectId => _s(raw, 'currentProjectId');
  bool get onSite => raw['onSite'] as bool? ?? false;
}

class Submission extends Model {
  const Submission(super.raw);

  String get type => _s(raw, 'type') ?? '';
  String? get projectId => _s(raw, 'projectId');
  String? get title => _s(raw, 'title');
  Json get payload => (raw['payload'] as Map?)?.cast<String, dynamic>() ?? {};
  String? get direction => _s(raw, 'direction');
  String? get authorEmployeeId => _s(raw, 'authorEmployeeId');
  String? get recipientEmployeeId => _s(raw, 'recipientEmployeeId');
  String? get assetId => _s(raw, 'assetId');
  String? get remitoId => _s(raw, 'remitoId');
  String? get reviewStatus => _s(raw, 'reviewStatus');
  String? get reviewNote => _s(raw, 'reviewNote');
  DateTime? get occurredAt => _d(raw, 'occurredAt');
  bool get isVoided => raw['voidedAt'] != null;

  /// Texto libre de una bitácora o informe.
  String get text => (payload['notes'] ?? payload['text'] ?? '').toString();
}

class IncidentDetail extends Model {
  const IncidentDetail(super.raw);

  String get submissionId => _s(raw, 'submissionId') ?? '';
  String get kind => _s(raw, 'kind') ?? 'OTHER';
  String? get severity => _s(raw, 'severity');
  String get status => _s(raw, 'status') ?? 'OPEN';
  String? get assetId => _s(raw, 'assetId');
}

class Requirement extends Model {
  const Requirement(super.raw);

  String get kind => _s(raw, 'kind') ?? '';
  String get status => _s(raw, 'status') ?? 'PENDING';
  String? get projectId => _s(raw, 'projectId');
  String? get requestedById => _s(raw, 'requestedById');
  DateTime? get requestedAt => _d(raw, 'requestedAt');
  String? get notes => _s(raw, 'notes');
  String? get resolutionNote => _s(raw, 'resolutionNote');
}

class RequirementItem extends Model {
  const RequirementItem(super.raw);

  String get requirementId => _s(raw, 'requirementId') ?? '';
  String? get modelId => _s(raw, 'modelId');
  String? get assetId => _s(raw, 'assetId');
  num get quantity => _n(raw, 'quantity') ?? 1;
  String? get description => _s(raw, 'description');
}

class CheckIn extends Model {
  const CheckIn(super.raw);

  String get employeeId => _s(raw, 'employeeId') ?? '';
  String get projectId => _s(raw, 'projectId') ?? '';
  String get type => _s(raw, 'type') ?? 'UP';
  DateTime? get occurredAt => _d(raw, 'occurredAt');
  bool get isVoided => raw['voidedAt'] != null;
}

class VerificationSchedule extends Model {
  const VerificationSchedule(super.raw);

  String? get projectId => _s(raw, 'projectId');
  String get name => _s(raw, 'name') ?? '';
  int? get photosPerItem => _n(raw, 'photosPerItem')?.toInt();
  DateTime? get nextDueAt => _d(raw, 'nextDueAt');
}
