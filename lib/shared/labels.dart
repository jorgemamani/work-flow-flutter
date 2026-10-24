import '../core/outbox/outbox_op.dart';
import '../l10n/app_localizations.dart';

/// Textos de los enums de la API (viajan en inglés, contrato §1).
extension EnumLabels on AppLocalizations {
  String assetStatus(String s) => switch (s) {
        'OPERATIONAL' => statusOperational,
        'RESERVED' => statusReserved,
        'IN_REPAIR' => statusInRepair,
        'DAMAGED' => statusDamaged,
        'LOST' => statusLost,
        'RETIRED' => statusRetired,
        _ => s,
      };

  String remitoStatus(String s) => switch (s) {
        'DRAFT' => remitoDraft,
        'PENDING_APPROVAL' => remitoPendingApproval,
        'APPROVED' => remitoApproved,
        'REJECTED' => remitoRejected,
        'IN_TRANSIT' => remitoInTransit,
        'RECEIVED' => remitoReceived,
        'RECEIVED_WITH_DIFFERENCES' => remitoReceivedWithDiff,
        'CONTROLLED' => remitoControlled,
        'CANCELLED' => remitoCancelled,
        _ => s,
      };

  String remitoType(String s) => switch (s) {
        'SHIPMENT' => remitoTypeShipment,
        'RETURN' => remitoTypeReturn,
        'TRANSFER' => remitoTypeTransfer,
        'WORKSHOP' => remitoTypeWorkshop,
        'PERSON_DELIVERY' => remitoTypePersonDelivery,
        _ => s,
      };

  String incidentKind(String s) => switch (s) {
        'MISSING' => incidentMissing,
        'DAMAGE' => incidentDamage,
        'LOSS' => incidentLoss,
        'CLAIM' => incidentClaim,
        _ => incidentOther,
      };

  String severity(String s) => switch (s) {
        'LOW' => severityLow,
        'MEDIUM' => severityMedium,
        'HIGH' => severityHigh,
        'CRITICAL' => severityCritical,
        _ => s,
      };

  String incidentStatus(String s) => switch (s) {
        'OPEN' => incidentOpen,
        'INVESTIGATING' => incidentInvestigating,
        'RESOLVED' => incidentResolved,
        'CLOSED' => incidentClosed,
        _ => s,
      };

  String requirementKind(String s) => switch (s) {
        'NEW_ITEMS' => reqNewItems,
        'WRITE_OFF' => reqWriteOff,
        'REPAIR' => reqRepair,
        _ => s,
      };

  String requirementStatus(String s) => switch (s) {
        'PENDING' => reqPending,
        'IN_TRANSFER' => reqInTransfer,
        'IN_PURCHASE' => reqInPurchase,
        'DELIVERED' => reqDelivered,
        'REJECTED' => reqRejected,
        'CANCELLED' => reqCancelled,
        _ => s,
      };

  String reviewStatus(String? s) => switch (s) {
        'APPROVED' => reviewApproved,
        'OBSERVED' => reviewObserved,
        _ => reviewPending,
      };

  String locationType(String s) => switch (s) {
        'PROJECT_ROOT' => locProjectRoot,
        'WAREHOUSE' => locWarehouse,
        'WORKSHOP' => locWorkshop,
        'OFFICE' => locOffice,
        'CAMP' => locCamp,
        'WORK_FRONT' => locWorkFront,
        _ => locOther,
      };

  String submissionType(String s) => switch (s) {
        'DAILY_LOG' => typeDailyLog,
        'REPORT' => typeReport,
        'INCIDENT' => typeIncident,
        'ASSET_AUDIT' => typeAssetAudit,
        'VERIFICATION' => typeVerification,
        'MOVEMENT_CHECKLIST' => typeMovementChecklist,
        _ => s,
      };

  String holderType(String s) => switch (s) {
        'LOCATION' => holderLocation,
        'ASSET' => holderAsset,
        'EMPLOYEE' => holderEmployee,
        _ => holderInTransit,
      };

  String outboxLabel(OutboxLabel label) {
    final a = label.args;
    return switch (label.key) {
      'opCreateAsset' => opCreateAsset(a['code'] ?? ''),
      'opMove' => opMove(a['code'] ?? ''),
      'opStatus' => opStatus(a['code'] ?? ''),
      'opReception' => opReception(a['number'] ?? ''),
      'opReturn' => opReturn,
      'opReturnSubmit' => opReturnSubmit,
      'opVerification' => opVerification(int.tryParse(a['count'] ?? '') ?? 0),
      'opDailyLog' => opDailyLog,
      'opIncident' => opIncident(a['title'] ?? ''),
      'opRequirement' => opRequirement(int.tryParse(a['count'] ?? '') ?? 0),
      'opCheckInUp' => opCheckInUp(a['name'] ?? ''),
      'opCheckInDown' => opCheckInDown(a['name'] ?? ''),
      'opPhoto' => opPhoto(a['what'] ?? ''),
      _ => label.key,
    };
  }

  /// Mensajes de la cola que no vienen de la API.
  String outboxError(String? raw) => switch (raw) {
        null => '',
        'photo_missing' => errorPhotoMissing,
        'offline' => offlineWillRetry,
        _ => raw,
      };
}
