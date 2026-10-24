import 'session_manager.dart';

/// `GET /auth/me`, guardado localmente para abrir la app sin señal.
class Profile {
  const Profile(this.raw);

  final Map<String, dynamic> raw;

  Map<String, dynamic> get _user => raw['user'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get _tenant =>
      raw['tenant'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic>? get _employee => raw['employee'] as Map<String, dynamic>?;
  Map<String, dynamic> get settings =>
      raw['settings'] as Map<String, dynamic>? ?? {};

  String get userId => _user['id'] as String? ?? '';
  String get firstName => _user['firstName'] as String? ?? '';
  String get fullName =>
      '${_user['firstName'] ?? ''} ${_user['lastName'] ?? ''}'.trim();
  String? get email => _user['email'] as String?;
  String? get documentNumber => _user['documentNumber'] as String?;
  String? get language => _user['language'] as String?;

  String get tenantId => _tenant['id'] as String? ?? '';
  String get tenantName => _tenant['name'] as String? ?? '';
  String? get tenantCuit => _tenant['cuit'] as String?;

  /// Clave para saber si los datos locales son de esta persona y empresa.
  String get ownerKey => '$userId@$tenantId';

  String? get employeeId => _employee?['id'] as String?;
  String? get currentProjectId => _employee?['currentProjectId'] as String?;
  bool get onSite => _employee?['onSite'] as bool? ?? false;
  String? get qualificationStatus => _employee?['qualificationStatus'] as String?;

  List<Membership> get memberships => [
        for (final m in raw['memberships'] as List? ?? const [])
          Membership.fromJson(m as Map<String, dynamic>),
      ];

  int get maxPhotosPerVerification =>
      ((settings['maxPhotosPerVerification'] as num?)?.toInt() ?? 5).clamp(1, 10);
  int get offlineDays => (settings['offlineDays'] as num?)?.toInt() ?? 14;

  List<String> get _global => [
        for (final p in raw['permissions'] as List? ?? const []) p as String,
      ];

  Map<String, List<String>> get _byProject {
    final m = raw['projectPermissions'] as Map<String, dynamic>? ?? {};
    return m.map((k, v) => MapEntry(k, [for (final p in v as List) p as String]));
  }

  /// `modulo.accion` con wildcards (`inventory.*`, `*`). Solo para UX: la API
  /// valida siempre (contrato §2).
  bool can(String permission, {String? projectId}) {
    if (_global.any((p) => _matches(p, permission))) return true;
    final scoped = projectId == null
        ? _byProject.values.expand((e) => e)
        : (_byProject[projectId] ?? const <String>[]);
    return scoped.any((p) => _matches(p, permission));
  }

  static bool _matches(String granted, String wanted) {
    if (granted == '*' || granted == wanted) return true;
    if (granted.endsWith('.*')) {
      return wanted.startsWith(granted.substring(0, granted.length - 1));
    }
    return false;
  }

  /// Copia con el estado de empleado cambiado (subida/bajada optimista).
  Profile withEmployee({bool? onSite, String? currentProjectId, bool clearProject = false}) {
    final e = Map<String, dynamic>.from(_employee ?? {});
    if (onSite != null) e['onSite'] = onSite;
    if (clearProject) {
      e['currentProjectId'] = null;
    } else if (currentProjectId != null) {
      e['currentProjectId'] = currentProjectId;
    }
    return Profile({...raw, 'employee': e});
  }
}

abstract final class Perms {
  static const remitosConfirm = 'remitos.confirm';
  static const remitosWrite = 'remitos.write';
  static const verificationsSubmit = 'verifications.submit';
  static const moveWithinProject = 'inventory.move_within_project';
  static const checkinsSelf = 'checkins.self';
  static const checkinsWriteOthers = 'checkins.write_others';
  static const incidentsCreate = 'incidents.create';
  static const submissionsCreate = 'submissions.create';
  static const requirementsCreate = 'requirements.create';
  static const inventoryWrite = 'inventory.write';
  static const inventoryMove = 'inventory.move';
  static const remitosControl = 'remitos.control';
  static const employeesRead = 'employees.read';
  static const photosSetCurrent = 'photos.set_current';
}
