// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabItems => 'Ítems';

  @override
  String get tabRecords => 'Registros';

  @override
  String get tabAccount => 'Cuenta';

  @override
  String get tabDailyLogs => 'Bitácoras';

  @override
  String get tabVerifications => 'Verificaciones';

  @override
  String get tabIncidents => 'Incidencias';

  @override
  String get tabRequirements => 'Solicitudes';

  @override
  String get loginField => 'Campo';

  @override
  String get loginOffice => 'Oficina';

  @override
  String get companyCuit => 'CUIT de la empresa';

  @override
  String get companyCuitOptional => 'CUIT de la empresa (opcional)';

  @override
  String get invalidCuit => 'El CUIT tiene 11 dígitos';

  @override
  String get documentNumber => 'DNI o CUIL';

  @override
  String get pin => 'PIN';

  @override
  String get email => 'Email';

  @override
  String get password => 'Contraseña';

  @override
  String get signIn => 'Ingresar';

  @override
  String get requiredField => 'Obligatorio';

  @override
  String get loginOffline =>
      'Sin conexión. Para ingresar por primera vez hace falta señal.';

  @override
  String get loginHelp =>
      '¿Olvidaste la contraseña o el PIN? Pedile a tu empresa que los resetee.';

  @override
  String get sessionExpiredKeepQueue =>
      'Tu sesión venció. Ingresá de nuevo: lo que registraste sin señal se conserva y se envía después.';

  @override
  String get chooseCompany => 'Elegí la empresa';

  @override
  String get chooseCompanyHelp =>
      'Trabajás en más de una empresa. ¿Con cuál querés entrar?';

  @override
  String helloName(String name) {
    return 'Hola, $name';
  }

  @override
  String get noProject =>
      'No tenés un proyecto asignado. Cuando te asignen uno, aparece acá después de sincronizar.';

  @override
  String get noProjectShort => 'Sin proyecto';

  @override
  String get downloadingProject => 'Descargando los datos del proyecto…';

  @override
  String get changeProject => 'Cambiar proyecto';

  @override
  String get onSite => 'Arriba en la mina';

  @override
  String get offSite => 'Abajo';

  @override
  String get quickActions => 'Qué querés hacer';

  @override
  String get summary => 'Resumen';

  @override
  String get actionScan => 'Escanear';

  @override
  String get actionReceiveRemito => 'Recibir remito';

  @override
  String get actionVerification => 'Verificación';

  @override
  String get actionDailyLog => 'Bitácora';

  @override
  String get actionIncident => 'Incidencia';

  @override
  String get actionCheckUp => 'Registrar subida';

  @override
  String get actionCheckDown => 'Registrar bajada';

  @override
  String get actionRequirement => 'Solicitud';

  @override
  String get actionReturn => 'Devolución';

  @override
  String get myItems => 'A mi cargo';

  @override
  String get projectItems => 'Del proyecto';

  @override
  String get receivedReports => 'Informes recibidos';

  @override
  String get offline => 'Sin conexión';

  @override
  String get online => 'Con conexión';

  @override
  String get offlineWorkingLocally => 'trabajando con los datos del teléfono';

  @override
  String lastSync(String when) {
    return 'Última sync $when';
  }

  @override
  String get neverSynced => 'Todavía no se sincronizó';

  @override
  String get allSynced => 'Todo enviado';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acciones pendientes de enviar',
      one: '1 acción pendiente de enviar',
    );
    return '$_temp0';
  }

  @override
  String failedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acciones fallaron: revisalas',
      one: '1 acción falló: revisala',
    );
    return '$_temp0';
  }

  @override
  String get agoNow => 'recién';

  @override
  String agoMinutes(int count) {
    return 'hace $count min';
  }

  @override
  String agoHours(int count) {
    return 'hace $count h';
  }

  @override
  String agoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get syncTitle => 'Sincronización';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncing => 'Sincronizando…';

  @override
  String get workOffline => 'Trabajar sin conexión';

  @override
  String get workOfflineHelp =>
      'No usa la red aunque haya señal. Todo se guarda en el teléfono.';

  @override
  String failedTitle(int count) {
    return 'Con problemas ($count)';
  }

  @override
  String pendingTitle(int count) {
    return 'Pendientes en orden ($count)';
  }

  @override
  String get nothingPending => 'No hay nada pendiente';

  @override
  String attempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos',
      one: '1 intento',
    );
    return '$_temp0';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get discard => 'Descartar';

  @override
  String get understood => 'Entendido';

  @override
  String get redownloadAll => 'Volver a descargar todo';

  @override
  String get offlineWillRetry => 'Sin señal: se reintenta solo';

  @override
  String get errorPhotoMissing => 'La foto ya no está en el teléfono';

  @override
  String get pendingSync => 'Sin enviar';

  @override
  String get savedQueued => 'Guardado. Se envía cuando haya señal.';

  @override
  String get savedLocallyHint =>
      'Se guarda en el teléfono con la hora de ahora y se envía solo al tener señal.';

  @override
  String get needsConnection => 'Esto necesita conexión';

  @override
  String opMove(String code) {
    return 'Mover $code';
  }

  @override
  String opStatus(String code) {
    return 'Cambiar estado de $code';
  }

  @override
  String opReception(String number) {
    return 'Recepción del remito $number';
  }

  @override
  String get opReturn => 'Remito de devolución';

  @override
  String get opReturnSubmit => 'Enviar remito de devolución';

  @override
  String opVerification(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verificación de $count ítems',
      one: 'Verificación de 1 ítem',
    );
    return '$_temp0';
  }

  @override
  String get opDailyLog => 'Bitácora diaria';

  @override
  String opIncident(String title) {
    return 'Incidencia: $title';
  }

  @override
  String opRequirement(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Solicitud de $count ítems',
      one: 'Solicitud de 1 ítem',
    );
    return '$_temp0';
  }

  @override
  String opCheckInUp(String name) {
    return 'Subida de $name';
  }

  @override
  String opCheckInDown(String name) {
    return 'Bajada de $name';
  }

  @override
  String opPhoto(String what) {
    return 'Foto ($what)';
  }

  @override
  String get searchItems => 'Buscar por código, modelo o patente';

  @override
  String get noMyItems => 'No tenés ítems a tu cargo';

  @override
  String get noProjectItems => 'No hay ítems en el proyecto';

  @override
  String get consumables => 'Consumibles';

  @override
  String get inTransit => 'En tránsito';

  @override
  String get withPerson => 'Con';

  @override
  String get itemNotFound => 'No se encontró el ítem';

  @override
  String get noCurrentPhoto => 'Sin foto vigente';

  @override
  String get inOpenRemito => 'En un remito abierto';

  @override
  String get whereIsIt => 'Dónde está';

  @override
  String sinceAgo(String when) {
    return 'Desde $when';
  }

  @override
  String get details => 'Datos';

  @override
  String get internalCode => 'Código interno';

  @override
  String get barcode => 'Código de barras';

  @override
  String get serialNumber => 'N° de serie';

  @override
  String get licensePlate => 'Patente';

  @override
  String get category => 'Categoría';

  @override
  String get custodian => 'Responsable';

  @override
  String get description => 'Descripción';

  @override
  String contents(int count) {
    return 'Contiene ($count)';
  }

  @override
  String get moveItem => 'Mover';

  @override
  String get changeStatus => 'Cambiar estado';

  @override
  String get reportIncident => 'Reportar una incidencia';

  @override
  String get requestRepairOrWriteOff => 'Pedir reparación o baja';

  @override
  String nowAt(String where) {
    return 'Ahora en: $where';
  }

  @override
  String get toMyCharge => 'A mi cargo';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get confirmMove => 'Confirmar movimiento';

  @override
  String get status => 'Estado';

  @override
  String get condition => 'Condición';

  @override
  String get reasonOptional => 'Motivo (opcional)';

  @override
  String get save => 'Guardar';

  @override
  String get scanTitle => 'Escanear código';

  @override
  String get cameraUnavailable =>
      'No se pudo abrir la cámara. Tipeá el código abajo.';

  @override
  String codeNotFound(String code) {
    return 'No hay ningún ítem con el código $code';
  }

  @override
  String get typeCode => 'O tipeá el código';

  @override
  String get statusOperational => 'Operativo';

  @override
  String get statusReserved => 'Reservado';

  @override
  String get statusInRepair => 'En reparación';

  @override
  String get statusDamaged => 'Dañado';

  @override
  String get statusLost => 'Perdido';

  @override
  String get statusRetired => 'De baja';

  @override
  String get holderLocation => 'Ubicación';

  @override
  String get holderAsset => 'Contenedor o vehículo';

  @override
  String get holderEmployee => 'Persona';

  @override
  String get holderInTransit => 'En tránsito';

  @override
  String get locProjectRoot => 'La mina';

  @override
  String get locWarehouse => 'Almacén';

  @override
  String get locWorkshop => 'Taller';

  @override
  String get locOffice => 'Oficina';

  @override
  String get locCamp => 'Campamento';

  @override
  String get locWorkFront => 'Frente de obra';

  @override
  String get locOther => 'Otra';

  @override
  String get remitoDraft => 'Borrador';

  @override
  String get remitoPendingApproval => 'Pendiente de aprobación';

  @override
  String get remitoApproved => 'Aprobado';

  @override
  String get remitoRejected => 'Rechazado';

  @override
  String get remitoInTransit => 'En tránsito';

  @override
  String get remitoReceived => 'Recibido completo';

  @override
  String get remitoReceivedWithDiff => 'Recibido con diferencias';

  @override
  String get remitoControlled => 'Controlado';

  @override
  String get remitoCancelled => 'Anulado';

  @override
  String get remitoTypeShipment => 'Envío';

  @override
  String get remitoTypeReturn => 'Devolución';

  @override
  String get remitoTypeTransfer => 'Traslado';

  @override
  String get remitoTypeWorkshop => 'Envío a taller';

  @override
  String get remitoTypePersonDelivery => 'Entrega a persona';

  @override
  String get incomingRemitos => 'Remitos por recibir';

  @override
  String get noIncomingRemitos => 'No hay remitos en camino a este proyecto';

  @override
  String fromTo(String origin, String dest) {
    return '$origin → $dest';
  }

  @override
  String dispatchedAgo(String when) {
    return 'Despachado $when';
  }

  @override
  String get recentRemitos => 'Remitos recientes';

  @override
  String get remitoNotFound => 'No se encontró el remito';

  @override
  String receiveRemitoTitle(String number) {
    return 'Recibir remito $number';
  }

  @override
  String get receptionHelp =>
      'Marcá cada ítem. Faltante: queda en tránsito y avisa a logística. Dañado: foto obligatoria.';

  @override
  String get markReceived => 'Recibido';

  @override
  String get markMissing => 'Faltante';

  @override
  String get markDamaged => 'Dañado';

  @override
  String sentQuantity(String qty) {
    return 'Enviado: $qty';
  }

  @override
  String get receivedQuantity => 'Cantidad recibida';

  @override
  String get lessThanSent =>
      'Menos que lo enviado: la diferencia se informa como faltante';

  @override
  String get whatHappened => '¿Qué pasó? (opcional)';

  @override
  String get damagedNeedsPhoto =>
      'Los ítems dañados necesitan al menos una foto';

  @override
  String get confirmReception => 'Confirmar recepción';

  @override
  String receptionSummary(int ok, int missing, int damaged) {
    return 'Recibidos: $ok · Faltantes: $missing · Dañados: $damaged';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get returnRemitoTitle => 'Remito de devolución';

  @override
  String get origin => 'Origen';

  @override
  String get destinationWarehouse => 'Almacén de destino';

  @override
  String get itemsToReturn => 'Qué baja';

  @override
  String available(String qty) {
    return 'Disponible: $qty';
  }

  @override
  String createReturn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Armar devolución ($count)',
      one: 'Armar devolución (1)',
      zero: 'Armar devolución',
    );
    return '$_temp0';
  }

  @override
  String get scheduleOptional => 'Programación (opcional)';

  @override
  String get noSchedule => 'Sin programación';

  @override
  String photoLimitInfo(int count) {
    return 'Hasta $count fotos por ítem';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ítems',
      one: '1 ítem',
      zero: 'Sin ítems',
    );
    return '$_temp0';
  }

  @override
  String get chooseItems => 'Elegir ítems';

  @override
  String get chooseItemsToVerify => 'Ítems a verificar';

  @override
  String get verificationEmpty => 'Elegí los ítems que vas a verificar';

  @override
  String get requiresPhoto => 'Requiere foto';

  @override
  String verificationMissingPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan fotos de $count ítems que las requieren',
      one: 'Falta la foto de 1 ítem que la requiere',
    );
    return '$_temp0';
  }

  @override
  String photosOverLimit(int count) {
    return 'Máximo $count fotos por ítem';
  }

  @override
  String get generalNotes => 'Observaciones generales';

  @override
  String get submitVerification => 'Enviar verificación';

  @override
  String get done => 'Listo';

  @override
  String get photoFromCamera => 'Sacar foto';

  @override
  String get photoFromGallery => 'Elegir de la galería';

  @override
  String get photoRequired => 'Foto obligatoria';

  @override
  String photosCount(int count, int max) {
    return '$count de $max fotos';
  }

  @override
  String get photos => 'Fotos';

  @override
  String get noDailyLogs => 'Todavía no cargaste bitácoras';

  @override
  String get noVerifications => 'Todavía no hiciste verificaciones';

  @override
  String get noReceivedReports => 'No recibiste informes';

  @override
  String get noIncidents => 'No hay incidencias';

  @override
  String get noRequirements => 'No hay solicitudes';

  @override
  String get reviewApproved => 'Aprobado';

  @override
  String get reviewObserved => 'Observado';

  @override
  String get reviewPending => 'Sin revisar';

  @override
  String get typeDailyLog => 'Bitácora';

  @override
  String get typeReport => 'Informe';

  @override
  String get typeIncident => 'Incidencia';

  @override
  String get typeAssetAudit => 'Auditoría de ítem';

  @override
  String get typeVerification => 'Verificación';

  @override
  String get typeMovementChecklist => 'Checklist de movimiento';

  @override
  String get whatDidYouDoToday => '¿Qué hiciste hoy?';

  @override
  String get tasks => 'Tareas';

  @override
  String get addTask => 'Agregar tarea';

  @override
  String get incidentTitle => 'Título';

  @override
  String get kind => 'Tipo';

  @override
  String get severityLabel => 'Gravedad';

  @override
  String get relatedItem => 'Ítem (opcional)';

  @override
  String get noItemSelected => 'Ninguno: tocá para escanear o buscar';

  @override
  String get send => 'Enviar';

  @override
  String get incidentMissing => 'Faltante';

  @override
  String get incidentDamage => 'Daño';

  @override
  String get incidentLoss => 'Pérdida';

  @override
  String get incidentClaim => 'Reclamo';

  @override
  String get incidentOther => 'Otra';

  @override
  String get severityLow => 'Baja';

  @override
  String get severityMedium => 'Media';

  @override
  String get severityHigh => 'Alta';

  @override
  String get severityCritical => 'Crítica';

  @override
  String get incidentOpen => 'Abierta';

  @override
  String get incidentInvestigating => 'En análisis';

  @override
  String get incidentResolved => 'Resuelta';

  @override
  String get incidentClosed => 'Cerrada';

  @override
  String get reqNewItems => 'Ítems nuevos';

  @override
  String get reqWriteOff => 'Baja';

  @override
  String get reqRepair => 'Reparación';

  @override
  String get reqPending => 'Pendiente';

  @override
  String get reqInTransfer => 'En traslado';

  @override
  String get reqInPurchase => 'En compra';

  @override
  String get reqDelivered => 'Entregada';

  @override
  String get reqRejected => 'Rechazada';

  @override
  String get reqCancelled => 'Cancelada';

  @override
  String get describeItem => 'Describí qué necesitás';

  @override
  String get quantity => 'Cantidad';

  @override
  String get addProjectItem => 'Agregar ítem del proyecto';

  @override
  String get fromCatalog => 'Del catálogo';

  @override
  String get otherItem => 'Otro';

  @override
  String get neededByOptional => 'Para cuándo (opcional)';

  @override
  String get checkInTitle => 'Subida y bajada';

  @override
  String confirmCheckUp(String name) {
    return '¿Registrar la subida de $name?';
  }

  @override
  String confirmCheckDown(String name) {
    return '¿Registrar la bajada de $name?';
  }

  @override
  String checkInTimeNote(String time) {
    return 'Queda registrada a las $time (hora del teléfono).';
  }

  @override
  String get youAreOnSite => 'Estás arriba';

  @override
  String get youAreOffSite => 'Estás abajo';

  @override
  String get registerUp => 'Registrar subida';

  @override
  String get registerDown => 'Registrar bajada';

  @override
  String get myCheckIns => 'Mis marcaciones';

  @override
  String get wentUp => 'Subida';

  @override
  String get wentDown => 'Bajada';

  @override
  String get otherPeople => 'Otras personas';

  @override
  String get noEmployees => 'No hay personas para mostrar';

  @override
  String get onSiteRequiredTitle => 'Primero registrá tu subida';

  @override
  String onSiteRequiredBody(String project) {
    return 'Para hacer esto en $project tenés que figurar arriba. ¿Registramos tu subida ahora? Se envía antes que lo demás.';
  }

  @override
  String get registerUpAndContinue => 'Registrar subida y seguir';

  @override
  String get newItem => 'Nuevo ítem';

  @override
  String get createItem => 'Dar de alta';

  @override
  String get chooseModel => 'Elegí el modelo';

  @override
  String get searchModels => 'Buscar modelo o marca';

  @override
  String get noModels => 'No hay modelos. Se cargan desde la web.';

  @override
  String get codes => 'Códigos';

  @override
  String get barcodeOptional => 'Código de barras del fabricante (opcional)';

  @override
  String get serialNumberOptional => 'N° de serie (opcional)';

  @override
  String get serialRequired => 'Exige n° de serie';

  @override
  String get custodyRequired => 'Lleva responsable';

  @override
  String get vehicle => 'Vehículo';

  @override
  String get container => 'Contenedor';

  @override
  String get vehicleData => 'Datos del vehículo';

  @override
  String get chassisNumber => 'N° de chasis';

  @override
  String get engineNumber => 'N° de motor';

  @override
  String get year => 'Año';

  @override
  String get initialLocation => 'Dónde queda';

  @override
  String get chooseLocation => 'Elegí dónde queda';

  @override
  String get companyLocation => 'de la empresa';

  @override
  String get me => 'yo';

  @override
  String get custodianRequired => 'Elegí el responsable';

  @override
  String get descriptionOptional => 'Descripción (opcional)';

  @override
  String codeAlreadyUsed(String code) {
    return 'Ya hay un ítem con el código $code';
  }

  @override
  String get createWithThisCode => 'Dar de alta un ítem con este código';

  @override
  String get scanCodeTitle => 'Escanear código';

  @override
  String opCreateAsset(String code) {
    return 'Alta de $code';
  }

  @override
  String get fixCode => 'Corregir código';

  @override
  String get fixCodeTitle => 'Otro código interno';

  @override
  String get catTool => 'Herramienta';

  @override
  String get catVehicle => 'Vehículo';

  @override
  String get catEpp => 'EPP';

  @override
  String get catTechEquipment => 'Equipo tecnológico';

  @override
  String get catToolbox => 'Caja de herramientas';

  @override
  String get catCableAccessory => 'Cables y accesorios';

  @override
  String get catConsumable => 'Consumible';

  @override
  String get catInstrument => 'Instrumento';

  @override
  String get catEquipment => 'Equipo';

  @override
  String get catClothing => 'Indumentaria';

  @override
  String get identifierLabel => 'Email o DNI/CUIL';

  @override
  String get identifierHint => 'nombre@empresa.com o 30111222';

  @override
  String get invalidIdentifier => 'Ingresá un email o un DNI/CUIL';

  @override
  String get secretLabel => 'Contraseña o PIN';

  @override
  String get sectionProject => 'En el proyecto';

  @override
  String get sectionLogistics => 'Logística';

  @override
  String get settings => 'Ajustes';

  @override
  String get changePin => 'Cambiar PIN';

  @override
  String get switchCompany => 'Cambiar de empresa';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'El del teléfono';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get logoutConfirm => '¿Cerrar la sesión en este teléfono?';

  @override
  String logoutWithPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count acciones sin enviar: si cerrás la sesión se pierden.',
      one: 'Hay 1 acción sin enviar: si cerrás la sesión se pierde.',
    );
    return '$_temp0';
  }

  @override
  String get pendingBlocksSwitch =>
      'Primero tienen que enviarse las acciones pendientes';

  @override
  String dniValue(String dni) {
    return 'DNI $dni';
  }

  @override
  String get currentPin => 'PIN actual';

  @override
  String get newPin => 'PIN nuevo';

  @override
  String get repeatPin => 'Repetí el PIN nuevo';

  @override
  String get pinTooShort => 'Entre 4 y 8 dígitos';

  @override
  String get pinMismatch => 'No coinciden';

  @override
  String get pinChanged => 'PIN cambiado';

  @override
  String connSavedNotSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guardados sin enviar',
      one: '1 guardado sin enviar',
    );
    return '$_temp0';
  }

  @override
  String get connAllSavedOnPhone => 'Todo guardado en el teléfono';

  @override
  String connSending(int count) {
    return 'Enviando $count…';
  }

  @override
  String connWithProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count con problemas',
      one: '1 con problemas',
    );
    return '$_temp0';
  }

  @override
  String get connSessionExpired => 'Sesión vencida';

  @override
  String get back => 'Volver';

  @override
  String get addPhotoShort => 'Agregar';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginFirstTime =>
      'La primera vez hace falta señal. Después funciona sin conexión.';

  @override
  String get optional => '(opcional)';

  @override
  String get homeTodo => 'Para hacer';

  @override
  String homeUpSince(String date) {
    return 'Subiste el $date';
  }

  @override
  String homeReceiveRemito(String number) {
    return 'Recibir remito $number';
  }

  @override
  String homeDueOn(String date) {
    return 'Vence el $date';
  }

  @override
  String get homeDailyLogToday => 'Bitácora de hoy';

  @override
  String get homeDailyLogMissing => 'Todavía no la cargaste';

  @override
  String get homeNothingTodo => 'Nada pendiente por ahora.';

  @override
  String get homeReviewSync => 'Revisalo en Sincronización';

  @override
  String get scanAimHint => 'Apuntá al código de barras o al QR';

  @override
  String get scanWriteCode => 'Escribir el código';

  @override
  String get scanViewItem => 'Ver el ítem';

  @override
  String get scanAgain => 'Escanear otro';

  @override
  String get torch => 'Linterna';

  @override
  String get close => 'Cerrar';

  @override
  String get itemFound => 'Ítem encontrado';

  @override
  String inContainer(String name) {
    return 'en $name';
  }

  @override
  String inChargeOf(String name) {
    return 'A cargo de $name';
  }

  @override
  String get search => 'Buscar';

  @override
  String get currentPhoto => 'Foto vigente';

  @override
  String get remitosTitle => 'Remitos';

  @override
  String remitosTowards(String name) {
    return 'Lo que viene hacia $name';
  }

  @override
  String toReceiveCount(int count) {
    return 'Por recibir · $count';
  }

  @override
  String get receiveTitle => 'Recibir remito';

  @override
  String reviewedOf(int done, int total) {
    return '$done de $total revisados';
  }

  @override
  String differencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diferencias',
      one: '1 diferencia',
      zero: 'Sin diferencias',
    );
    return '$_temp0';
  }

  @override
  String get optArrived => 'Llegó';

  @override
  String get optMissing => 'Falta';

  @override
  String get optDamaged => 'Dañado';

  @override
  String get howItArrived => 'Cómo llegó';

  @override
  String get notReviewed => 'Sin revisar';

  @override
  String get withDifference => 'Con diferencia';

  @override
  String get oneLess => 'Uno menos';

  @override
  String get oneMore => 'Uno más';

  @override
  String get unitsReceived => 'recibidos';

  @override
  String shortBy(String qty) {
    return 'Faltan $qty. Al confirmar se avisa a logística.';
  }

  @override
  String leftToReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Falta revisar $count ítems',
      one: 'Falta revisar 1 ítem',
    );
    return '$_temp0';
  }

  @override
  String get markEachItem => 'Marcá cómo llegó cada ítem para confirmar.';

  @override
  String get confirmWithDifferences => 'Confirmar con diferencias';

  @override
  String get sentWhenSignal =>
      'Se envía apenas haya señal. Queda tu nombre y la hora.';

  @override
  String get scanToMark => 'Escanear código';

  @override
  String notInRemito(String code) {
    return '$code no está en este remito';
  }

  @override
  String get damagePhotoRequired => 'Foto del daño (obligatoria)';

  @override
  String get qualTitle => 'Habilitaciones para subir';

  @override
  String get qualRow => 'Documentación';

  @override
  String get qualOk => 'Vigente';

  @override
  String get qualExpiring => 'Vence pronto';

  @override
  String get qualExpired => 'Vencida';

  @override
  String get qualExpiredNote =>
      'Tenés documentación vencida. Podés registrar la subida igual: queda marcada y le avisamos a RR. HH.';

  @override
  String get lastRecords => 'Últimos registros';

  @override
  String get registerForOther => 'Registrar para otra persona';

  @override
  String get fromThePhone => 'desde la app';

  @override
  String rightNowAt(String time) {
    return 'ahora · $time';
  }

  @override
  String photosDoneOf(int done, int total) {
    return '$done de $total con foto';
  }

  @override
  String takePhotoOf(String name) {
    return 'Sacar foto de $name';
  }

  @override
  String photoReadyOf(String name) {
    return 'Foto lista de $name. Tocá para sacar otra';
  }

  @override
  String get verificationPhotosNote =>
      'Las fotos muestran cómo está cada ítem. No cambian su estado: si algo está roto, reportalo como incidencia.';

  @override
  String get sentWhenSignalShort => 'Se envía apenas haya señal.';

  @override
  String dueOnShort(String date) {
    return 'vence el $date';
  }

  @override
  String get showDetails => 'Condición, más fotos y notas';

  @override
  String get dailyLogTitle => 'Bitácora de hoy';

  @override
  String get whatWasDoneToday => 'Qué se hizo hoy';

  @override
  String get toolsAndVehicles => 'Herramientas y vehículos';

  @override
  String get allGood => 'Todo bien';

  @override
  String get somethingWrong => 'Hay algo';

  @override
  String get news => 'Novedades';

  @override
  String get needsFixReport => '¿Hay que arreglarlo? Reportalo como incidencia';

  @override
  String get photosOptional => '(opcional)';

  @override
  String get saveDailyLog => 'Guardar bitácora';

  @override
  String get savedOnPhoneSentLater =>
      'Se guarda en el teléfono y se envía cuando haya señal.';

  @override
  String get whatHappenedTitle => 'Qué pasó';

  @override
  String get hintMissing => 'No llegó o no está';

  @override
  String get hintDamage => 'Está roto o falla';

  @override
  String get hintLoss => 'No sabemos dónde está';

  @override
  String get hintClaim => 'Un reclamo a logística';

  @override
  String get hintOther => 'Cualquier otra cosa';

  @override
  String get itemLabel => 'Ítem';

  @override
  String get change => 'Cambiar';

  @override
  String get choose => 'Elegir';

  @override
  String get tellBriefly => 'Contalo en pocas palabras';

  @override
  String get photoRequiredIfDamage => '· obligatoria si hay un daño';

  @override
  String get notifyLogistics => 'Avisar a logística';

  @override
  String get seeAnswerInRecords => 'Vas a ver la respuesta en Registros.';

  @override
  String get syncPendingTitle => 'Envíos pendientes';

  @override
  String get retriesAlone => 'sin señal, se reintenta solo';

  @override
  String get cameraUnavailableWrite =>
      'No se pudo abrir la cámara. Escribí el código.';
}
