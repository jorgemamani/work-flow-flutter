/// Una respuesta de `GET /sync/changes` (contrato §3).
class SyncPage {
  const SyncPage({
    required this.cursor,
    required this.hasMore,
    required this.changes,
    required this.deleted,
    this.serverTime,
  });

  final String cursor;
  final bool hasMore;
  final Map<String, List<Map<String, dynamic>>> changes;
  final Map<String, List<String>> deleted;
  final DateTime? serverTime;

  factory SyncPage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final changes = <String, List<Map<String, dynamic>>>{};
    (data['changes'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      changes[k] = [
        for (final r in v as List) Map<String, dynamic>.from(r as Map),
      ];
    });
    final deleted = <String, List<String>>{};
    (data['deleted'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      deleted[k] = [for (final id in v as List) id as String];
    });
    return SyncPage(
      cursor: data['cursor'] as String,
      hasMore: data['hasMore'] as bool? ?? false,
      changes: changes,
      deleted: deleted,
      serverTime: DateTime.tryParse(data['serverTime'] as String? ?? ''),
    );
  }
}

/// Fuentes que guarda el teléfono. El servidor solo manda las que el usuario
/// puede ver; el resto se ignora.
abstract final class SyncSources {
  static const projects = 'projects';
  static const locations = 'locations';
  static const assets = 'assets';
  static const assetModels = 'asset_models';
  static const brands = 'brands';
  static const assetConditions = 'asset_conditions';
  static const stockBalances = 'stock_balances';
  static const remitos = 'remitos';
  static const remitoItems = 'remito_items';
  static const employees = 'employees';
  static const documentTypes = 'document_types';
  static const submissions = 'submissions';
  static const incidentDetails = 'incident_details';
  static const verificationLines = 'verification_lines';
  static const verificationSchedules = 'verification_schedules';
  static const attachments = 'attachments';
  static const requirements = 'requirements';
  static const requirementItems = 'requirement_items';
  static const checkIns = 'check_ins';
  static const assignments = 'assignments';
  static const notifications = 'notifications';

  static const all = <String>{
    projects,
    locations,
    assets,
    assetModels,
    brands,
    assetConditions,
    stockBalances,
    remitos,
    remitoItems,
    employees,
    documentTypes,
    submissions,
    incidentDetails,
    verificationLines,
    verificationSchedules,
    attachments,
    requirements,
    requirementItems,
    checkIns,
    assignments,
    notifications,
  };
}
