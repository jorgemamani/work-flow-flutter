import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @tabHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get tabHome;

  /// No description provided for @tabItems.
  ///
  /// In es, this message translates to:
  /// **'Ítems'**
  String get tabItems;

  /// No description provided for @tabRecords.
  ///
  /// In es, this message translates to:
  /// **'Registros'**
  String get tabRecords;

  /// No description provided for @tabAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get tabAccount;

  /// No description provided for @tabDailyLogs.
  ///
  /// In es, this message translates to:
  /// **'Bitácoras'**
  String get tabDailyLogs;

  /// No description provided for @tabVerifications.
  ///
  /// In es, this message translates to:
  /// **'Verificaciones'**
  String get tabVerifications;

  /// No description provided for @tabIncidents.
  ///
  /// In es, this message translates to:
  /// **'Incidencias'**
  String get tabIncidents;

  /// No description provided for @tabRequirements.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get tabRequirements;

  /// No description provided for @loginField.
  ///
  /// In es, this message translates to:
  /// **'Campo'**
  String get loginField;

  /// No description provided for @loginOffice.
  ///
  /// In es, this message translates to:
  /// **'Oficina'**
  String get loginOffice;

  /// No description provided for @companyCuit.
  ///
  /// In es, this message translates to:
  /// **'CUIT de la empresa'**
  String get companyCuit;

  /// No description provided for @companyCuitOptional.
  ///
  /// In es, this message translates to:
  /// **'CUIT de la empresa (opcional)'**
  String get companyCuitOptional;

  /// No description provided for @invalidCuit.
  ///
  /// In es, this message translates to:
  /// **'El CUIT tiene 11 dígitos'**
  String get invalidCuit;

  /// No description provided for @documentNumber.
  ///
  /// In es, this message translates to:
  /// **'DNI o CUIL'**
  String get documentNumber;

  /// No description provided for @pin.
  ///
  /// In es, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get signIn;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get requiredField;

  /// No description provided for @loginOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Para ingresar por primera vez hace falta señal.'**
  String get loginOffline;

  /// No description provided for @loginHelp.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste la contraseña o el PIN? Pedile a tu empresa que los resetee.'**
  String get loginHelp;

  /// No description provided for @sessionExpiredKeepQueue.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión venció. Ingresá de nuevo: lo que registraste sin señal se conserva y se envía después.'**
  String get sessionExpiredKeepQueue;

  /// No description provided for @chooseCompany.
  ///
  /// In es, this message translates to:
  /// **'Elegí la empresa'**
  String get chooseCompany;

  /// No description provided for @chooseCompanyHelp.
  ///
  /// In es, this message translates to:
  /// **'Trabajás en más de una empresa. ¿Con cuál querés entrar?'**
  String get chooseCompanyHelp;

  /// No description provided for @helloName.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String helloName(String name);

  /// No description provided for @noProject.
  ///
  /// In es, this message translates to:
  /// **'No tenés un proyecto asignado. Cuando te asignen uno, aparece acá después de sincronizar.'**
  String get noProject;

  /// No description provided for @noProjectShort.
  ///
  /// In es, this message translates to:
  /// **'Sin proyecto'**
  String get noProjectShort;

  /// No description provided for @downloadingProject.
  ///
  /// In es, this message translates to:
  /// **'Descargando los datos del proyecto…'**
  String get downloadingProject;

  /// No description provided for @changeProject.
  ///
  /// In es, this message translates to:
  /// **'Cambiar proyecto'**
  String get changeProject;

  /// No description provided for @onSite.
  ///
  /// In es, this message translates to:
  /// **'Arriba en la mina'**
  String get onSite;

  /// No description provided for @offSite.
  ///
  /// In es, this message translates to:
  /// **'Abajo'**
  String get offSite;

  /// No description provided for @quickActions.
  ///
  /// In es, this message translates to:
  /// **'Qué querés hacer'**
  String get quickActions;

  /// No description provided for @summary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get summary;

  /// No description provided for @actionScan.
  ///
  /// In es, this message translates to:
  /// **'Escanear'**
  String get actionScan;

  /// No description provided for @actionReceiveRemito.
  ///
  /// In es, this message translates to:
  /// **'Recibir remito'**
  String get actionReceiveRemito;

  /// No description provided for @actionVerification.
  ///
  /// In es, this message translates to:
  /// **'Verificación'**
  String get actionVerification;

  /// No description provided for @actionDailyLog.
  ///
  /// In es, this message translates to:
  /// **'Bitácora'**
  String get actionDailyLog;

  /// No description provided for @actionIncident.
  ///
  /// In es, this message translates to:
  /// **'Incidencia'**
  String get actionIncident;

  /// No description provided for @actionCheckUp.
  ///
  /// In es, this message translates to:
  /// **'Registrar subida'**
  String get actionCheckUp;

  /// No description provided for @actionCheckDown.
  ///
  /// In es, this message translates to:
  /// **'Registrar bajada'**
  String get actionCheckDown;

  /// No description provided for @actionRequirement.
  ///
  /// In es, this message translates to:
  /// **'Solicitud'**
  String get actionRequirement;

  /// No description provided for @actionReturn.
  ///
  /// In es, this message translates to:
  /// **'Devolución'**
  String get actionReturn;

  /// No description provided for @myItems.
  ///
  /// In es, this message translates to:
  /// **'A mi cargo'**
  String get myItems;

  /// No description provided for @projectItems.
  ///
  /// In es, this message translates to:
  /// **'Del proyecto'**
  String get projectItems;

  /// No description provided for @receivedReports.
  ///
  /// In es, this message translates to:
  /// **'Informes recibidos'**
  String get receivedReports;

  /// No description provided for @offline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In es, this message translates to:
  /// **'Con conexión'**
  String get online;

  /// No description provided for @offlineWorkingLocally.
  ///
  /// In es, this message translates to:
  /// **'trabajando con los datos del teléfono'**
  String get offlineWorkingLocally;

  /// No description provided for @lastSync.
  ///
  /// In es, this message translates to:
  /// **'Última sync {when}'**
  String lastSync(String when);

  /// No description provided for @neverSynced.
  ///
  /// In es, this message translates to:
  /// **'Todavía no se sincronizó'**
  String get neverSynced;

  /// No description provided for @allSynced.
  ///
  /// In es, this message translates to:
  /// **'Todo enviado'**
  String get allSynced;

  /// No description provided for @pendingCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 acción pendiente de enviar} other{{count} acciones pendientes de enviar}}'**
  String pendingCount(int count);

  /// No description provided for @failedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 acción falló: revisala} other{{count} acciones fallaron: revisalas}}'**
  String failedCount(int count);

  /// No description provided for @agoNow.
  ///
  /// In es, this message translates to:
  /// **'recién'**
  String get agoNow;

  /// No description provided for @agoMinutes.
  ///
  /// In es, this message translates to:
  /// **'hace {count} min'**
  String agoMinutes(int count);

  /// No description provided for @agoHours.
  ///
  /// In es, this message translates to:
  /// **'hace {count} h'**
  String agoHours(int count);

  /// No description provided for @agoDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{hace 1 día} other{hace {count} días}}'**
  String agoDays(int count);

  /// No description provided for @syncTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronización'**
  String get syncTitle;

  /// No description provided for @syncNow.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar ahora'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando…'**
  String get syncing;

  /// No description provided for @workOffline.
  ///
  /// In es, this message translates to:
  /// **'Trabajar sin conexión'**
  String get workOffline;

  /// No description provided for @workOfflineHelp.
  ///
  /// In es, this message translates to:
  /// **'No usa la red aunque haya señal. Todo se guarda en el teléfono.'**
  String get workOfflineHelp;

  /// No description provided for @failedTitle.
  ///
  /// In es, this message translates to:
  /// **'Con problemas ({count})'**
  String failedTitle(int count);

  /// No description provided for @pendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Pendientes en orden ({count})'**
  String pendingTitle(int count);

  /// No description provided for @nothingPending.
  ///
  /// In es, this message translates to:
  /// **'No hay nada pendiente'**
  String get nothingPending;

  /// No description provided for @attempts.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 intento} other{{count} intentos}}'**
  String attempts(int count);

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @discard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @redownloadAll.
  ///
  /// In es, this message translates to:
  /// **'Volver a descargar todo'**
  String get redownloadAll;

  /// No description provided for @offlineWillRetry.
  ///
  /// In es, this message translates to:
  /// **'Sin señal: se reintenta solo'**
  String get offlineWillRetry;

  /// No description provided for @errorPhotoMissing.
  ///
  /// In es, this message translates to:
  /// **'La foto ya no está en el teléfono'**
  String get errorPhotoMissing;

  /// No description provided for @pendingSync.
  ///
  /// In es, this message translates to:
  /// **'Sin enviar'**
  String get pendingSync;

  /// No description provided for @savedQueued.
  ///
  /// In es, this message translates to:
  /// **'Guardado. Se envía cuando haya señal.'**
  String get savedQueued;

  /// No description provided for @savedLocallyHint.
  ///
  /// In es, this message translates to:
  /// **'Se guarda en el teléfono con la hora de ahora y se envía solo al tener señal.'**
  String get savedLocallyHint;

  /// No description provided for @needsConnection.
  ///
  /// In es, this message translates to:
  /// **'Esto necesita conexión'**
  String get needsConnection;

  /// No description provided for @opMove.
  ///
  /// In es, this message translates to:
  /// **'Mover {code}'**
  String opMove(String code);

  /// No description provided for @opStatus.
  ///
  /// In es, this message translates to:
  /// **'Cambiar estado de {code}'**
  String opStatus(String code);

  /// No description provided for @opReception.
  ///
  /// In es, this message translates to:
  /// **'Recepción del remito {number}'**
  String opReception(String number);

  /// No description provided for @opReturn.
  ///
  /// In es, this message translates to:
  /// **'Remito de devolución'**
  String get opReturn;

  /// No description provided for @opReturnSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar remito de devolución'**
  String get opReturnSubmit;

  /// No description provided for @opVerification.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Verificación de 1 ítem} other{Verificación de {count} ítems}}'**
  String opVerification(int count);

  /// No description provided for @opDailyLog.
  ///
  /// In es, this message translates to:
  /// **'Bitácora diaria'**
  String get opDailyLog;

  /// No description provided for @opIncident.
  ///
  /// In es, this message translates to:
  /// **'Incidencia: {title}'**
  String opIncident(String title);

  /// No description provided for @opRequirement.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Solicitud de 1 ítem} other{Solicitud de {count} ítems}}'**
  String opRequirement(int count);

  /// No description provided for @opCheckInUp.
  ///
  /// In es, this message translates to:
  /// **'Subida de {name}'**
  String opCheckInUp(String name);

  /// No description provided for @opCheckInDown.
  ///
  /// In es, this message translates to:
  /// **'Bajada de {name}'**
  String opCheckInDown(String name);

  /// No description provided for @opPhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto ({what})'**
  String opPhoto(String what);

  /// No description provided for @searchItems.
  ///
  /// In es, this message translates to:
  /// **'Buscar por código, modelo o patente'**
  String get searchItems;

  /// No description provided for @noMyItems.
  ///
  /// In es, this message translates to:
  /// **'No tenés ítems a tu cargo'**
  String get noMyItems;

  /// No description provided for @noProjectItems.
  ///
  /// In es, this message translates to:
  /// **'No hay ítems en el proyecto'**
  String get noProjectItems;

  /// No description provided for @consumables.
  ///
  /// In es, this message translates to:
  /// **'Consumibles'**
  String get consumables;

  /// No description provided for @inTransit.
  ///
  /// In es, this message translates to:
  /// **'En tránsito'**
  String get inTransit;

  /// No description provided for @withPerson.
  ///
  /// In es, this message translates to:
  /// **'Con'**
  String get withPerson;

  /// No description provided for @itemNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el ítem'**
  String get itemNotFound;

  /// No description provided for @noCurrentPhoto.
  ///
  /// In es, this message translates to:
  /// **'Sin foto vigente'**
  String get noCurrentPhoto;

  /// No description provided for @inOpenRemito.
  ///
  /// In es, this message translates to:
  /// **'En un remito abierto'**
  String get inOpenRemito;

  /// No description provided for @whereIsIt.
  ///
  /// In es, this message translates to:
  /// **'Dónde está'**
  String get whereIsIt;

  /// No description provided for @sinceAgo.
  ///
  /// In es, this message translates to:
  /// **'Desde {when}'**
  String sinceAgo(String when);

  /// No description provided for @details.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get details;

  /// No description provided for @internalCode.
  ///
  /// In es, this message translates to:
  /// **'Código interno'**
  String get internalCode;

  /// No description provided for @barcode.
  ///
  /// In es, this message translates to:
  /// **'Código de barras'**
  String get barcode;

  /// No description provided for @serialNumber.
  ///
  /// In es, this message translates to:
  /// **'N° de serie'**
  String get serialNumber;

  /// No description provided for @licensePlate.
  ///
  /// In es, this message translates to:
  /// **'Patente'**
  String get licensePlate;

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @custodian.
  ///
  /// In es, this message translates to:
  /// **'Responsable'**
  String get custodian;

  /// No description provided for @description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description;

  /// No description provided for @contents.
  ///
  /// In es, this message translates to:
  /// **'Contiene ({count})'**
  String contents(int count);

  /// No description provided for @moveItem.
  ///
  /// In es, this message translates to:
  /// **'Mover'**
  String get moveItem;

  /// No description provided for @changeStatus.
  ///
  /// In es, this message translates to:
  /// **'Cambiar estado'**
  String get changeStatus;

  /// No description provided for @reportIncident.
  ///
  /// In es, this message translates to:
  /// **'Reportar una incidencia'**
  String get reportIncident;

  /// No description provided for @requestRepairOrWriteOff.
  ///
  /// In es, this message translates to:
  /// **'Pedir reparación o baja'**
  String get requestRepairOrWriteOff;

  /// No description provided for @nowAt.
  ///
  /// In es, this message translates to:
  /// **'Ahora en: {where}'**
  String nowAt(String where);

  /// No description provided for @toMyCharge.
  ///
  /// In es, this message translates to:
  /// **'A mi cargo'**
  String get toMyCharge;

  /// No description provided for @notesOptional.
  ///
  /// In es, this message translates to:
  /// **'Notas (opcional)'**
  String get notesOptional;

  /// No description provided for @confirmMove.
  ///
  /// In es, this message translates to:
  /// **'Confirmar movimiento'**
  String get confirmMove;

  /// No description provided for @status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get status;

  /// No description provided for @condition.
  ///
  /// In es, this message translates to:
  /// **'Condición'**
  String get condition;

  /// No description provided for @reasonOptional.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get reasonOptional;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @scanTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanear código'**
  String get scanTitle;

  /// No description provided for @cameraUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la cámara. Tipeá el código abajo.'**
  String get cameraUnavailable;

  /// No description provided for @codeNotFound.
  ///
  /// In es, this message translates to:
  /// **'No hay ningún ítem con el código {code}'**
  String codeNotFound(String code);

  /// No description provided for @typeCode.
  ///
  /// In es, this message translates to:
  /// **'O tipeá el código'**
  String get typeCode;

  /// No description provided for @statusOperational.
  ///
  /// In es, this message translates to:
  /// **'Operativo'**
  String get statusOperational;

  /// No description provided for @statusReserved.
  ///
  /// In es, this message translates to:
  /// **'Reservado'**
  String get statusReserved;

  /// No description provided for @statusInRepair.
  ///
  /// In es, this message translates to:
  /// **'En reparación'**
  String get statusInRepair;

  /// No description provided for @statusDamaged.
  ///
  /// In es, this message translates to:
  /// **'Dañado'**
  String get statusDamaged;

  /// No description provided for @statusLost.
  ///
  /// In es, this message translates to:
  /// **'Perdido'**
  String get statusLost;

  /// No description provided for @statusRetired.
  ///
  /// In es, this message translates to:
  /// **'De baja'**
  String get statusRetired;

  /// No description provided for @holderLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get holderLocation;

  /// No description provided for @holderAsset.
  ///
  /// In es, this message translates to:
  /// **'Contenedor o vehículo'**
  String get holderAsset;

  /// No description provided for @holderEmployee.
  ///
  /// In es, this message translates to:
  /// **'Persona'**
  String get holderEmployee;

  /// No description provided for @holderInTransit.
  ///
  /// In es, this message translates to:
  /// **'En tránsito'**
  String get holderInTransit;

  /// No description provided for @locProjectRoot.
  ///
  /// In es, this message translates to:
  /// **'La mina'**
  String get locProjectRoot;

  /// No description provided for @locWarehouse.
  ///
  /// In es, this message translates to:
  /// **'Almacén'**
  String get locWarehouse;

  /// No description provided for @locWorkshop.
  ///
  /// In es, this message translates to:
  /// **'Taller'**
  String get locWorkshop;

  /// No description provided for @locOffice.
  ///
  /// In es, this message translates to:
  /// **'Oficina'**
  String get locOffice;

  /// No description provided for @locCamp.
  ///
  /// In es, this message translates to:
  /// **'Campamento'**
  String get locCamp;

  /// No description provided for @locWorkFront.
  ///
  /// In es, this message translates to:
  /// **'Frente de obra'**
  String get locWorkFront;

  /// No description provided for @locOther.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get locOther;

  /// No description provided for @remitoDraft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get remitoDraft;

  /// No description provided for @remitoPendingApproval.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de aprobación'**
  String get remitoPendingApproval;

  /// No description provided for @remitoApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get remitoApproved;

  /// No description provided for @remitoRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get remitoRejected;

  /// No description provided for @remitoInTransit.
  ///
  /// In es, this message translates to:
  /// **'En tránsito'**
  String get remitoInTransit;

  /// No description provided for @remitoReceived.
  ///
  /// In es, this message translates to:
  /// **'Recibido completo'**
  String get remitoReceived;

  /// No description provided for @remitoReceivedWithDiff.
  ///
  /// In es, this message translates to:
  /// **'Recibido con diferencias'**
  String get remitoReceivedWithDiff;

  /// No description provided for @remitoControlled.
  ///
  /// In es, this message translates to:
  /// **'Controlado'**
  String get remitoControlled;

  /// No description provided for @remitoCancelled.
  ///
  /// In es, this message translates to:
  /// **'Anulado'**
  String get remitoCancelled;

  /// No description provided for @remitoTypeShipment.
  ///
  /// In es, this message translates to:
  /// **'Envío'**
  String get remitoTypeShipment;

  /// No description provided for @remitoTypeReturn.
  ///
  /// In es, this message translates to:
  /// **'Devolución'**
  String get remitoTypeReturn;

  /// No description provided for @remitoTypeTransfer.
  ///
  /// In es, this message translates to:
  /// **'Traslado'**
  String get remitoTypeTransfer;

  /// No description provided for @remitoTypeWorkshop.
  ///
  /// In es, this message translates to:
  /// **'Envío a taller'**
  String get remitoTypeWorkshop;

  /// No description provided for @remitoTypePersonDelivery.
  ///
  /// In es, this message translates to:
  /// **'Entrega a persona'**
  String get remitoTypePersonDelivery;

  /// No description provided for @incomingRemitos.
  ///
  /// In es, this message translates to:
  /// **'Remitos por recibir'**
  String get incomingRemitos;

  /// No description provided for @noIncomingRemitos.
  ///
  /// In es, this message translates to:
  /// **'No hay remitos en camino a este proyecto'**
  String get noIncomingRemitos;

  /// No description provided for @fromTo.
  ///
  /// In es, this message translates to:
  /// **'{origin} → {dest}'**
  String fromTo(String origin, String dest);

  /// No description provided for @dispatchedAgo.
  ///
  /// In es, this message translates to:
  /// **'Despachado {when}'**
  String dispatchedAgo(String when);

  /// No description provided for @recentRemitos.
  ///
  /// In es, this message translates to:
  /// **'Remitos recientes'**
  String get recentRemitos;

  /// No description provided for @remitoNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el remito'**
  String get remitoNotFound;

  /// No description provided for @receiveRemitoTitle.
  ///
  /// In es, this message translates to:
  /// **'Recibir remito {number}'**
  String receiveRemitoTitle(String number);

  /// No description provided for @receptionHelp.
  ///
  /// In es, this message translates to:
  /// **'Marcá cada ítem. Faltante: queda en tránsito y avisa a logística. Dañado: foto obligatoria.'**
  String get receptionHelp;

  /// No description provided for @markReceived.
  ///
  /// In es, this message translates to:
  /// **'Recibido'**
  String get markReceived;

  /// No description provided for @markMissing.
  ///
  /// In es, this message translates to:
  /// **'Faltante'**
  String get markMissing;

  /// No description provided for @markDamaged.
  ///
  /// In es, this message translates to:
  /// **'Dañado'**
  String get markDamaged;

  /// No description provided for @sentQuantity.
  ///
  /// In es, this message translates to:
  /// **'Enviado: {qty}'**
  String sentQuantity(String qty);

  /// No description provided for @receivedQuantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad recibida'**
  String get receivedQuantity;

  /// No description provided for @lessThanSent.
  ///
  /// In es, this message translates to:
  /// **'Menos que lo enviado: la diferencia se informa como faltante'**
  String get lessThanSent;

  /// No description provided for @whatHappened.
  ///
  /// In es, this message translates to:
  /// **'¿Qué pasó? (opcional)'**
  String get whatHappened;

  /// No description provided for @damagedNeedsPhoto.
  ///
  /// In es, this message translates to:
  /// **'Los ítems dañados necesitan al menos una foto'**
  String get damagedNeedsPhoto;

  /// No description provided for @confirmReception.
  ///
  /// In es, this message translates to:
  /// **'Confirmar recepción'**
  String get confirmReception;

  /// No description provided for @receptionSummary.
  ///
  /// In es, this message translates to:
  /// **'Recibidos: {ok} · Faltantes: {missing} · Dañados: {damaged}'**
  String receptionSummary(int ok, int missing, int damaged);

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @returnRemitoTitle.
  ///
  /// In es, this message translates to:
  /// **'Remito de devolución'**
  String get returnRemitoTitle;

  /// No description provided for @origin.
  ///
  /// In es, this message translates to:
  /// **'Origen'**
  String get origin;

  /// No description provided for @destinationWarehouse.
  ///
  /// In es, this message translates to:
  /// **'Almacén de destino'**
  String get destinationWarehouse;

  /// No description provided for @itemsToReturn.
  ///
  /// In es, this message translates to:
  /// **'Qué baja'**
  String get itemsToReturn;

  /// No description provided for @available.
  ///
  /// In es, this message translates to:
  /// **'Disponible: {qty}'**
  String available(String qty);

  /// No description provided for @createReturn.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Armar devolución} =1{Armar devolución (1)} other{Armar devolución ({count})}}'**
  String createReturn(int count);

  /// No description provided for @scheduleOptional.
  ///
  /// In es, this message translates to:
  /// **'Programación (opcional)'**
  String get scheduleOptional;

  /// No description provided for @noSchedule.
  ///
  /// In es, this message translates to:
  /// **'Sin programación'**
  String get noSchedule;

  /// No description provided for @photoLimitInfo.
  ///
  /// In es, this message translates to:
  /// **'Hasta {count} fotos por ítem'**
  String photoLimitInfo(int count);

  /// No description provided for @itemsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin ítems} =1{1 ítem} other{{count} ítems}}'**
  String itemsCount(int count);

  /// No description provided for @chooseItems.
  ///
  /// In es, this message translates to:
  /// **'Elegir ítems'**
  String get chooseItems;

  /// No description provided for @chooseItemsToVerify.
  ///
  /// In es, this message translates to:
  /// **'Ítems a verificar'**
  String get chooseItemsToVerify;

  /// No description provided for @verificationEmpty.
  ///
  /// In es, this message translates to:
  /// **'Elegí los ítems que vas a verificar'**
  String get verificationEmpty;

  /// No description provided for @requiresPhoto.
  ///
  /// In es, this message translates to:
  /// **'Requiere foto'**
  String get requiresPhoto;

  /// No description provided for @verificationMissingPhotos.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Falta la foto de 1 ítem que la requiere} other{Faltan fotos de {count} ítems que las requieren}}'**
  String verificationMissingPhotos(int count);

  /// No description provided for @photosOverLimit.
  ///
  /// In es, this message translates to:
  /// **'Máximo {count} fotos por ítem'**
  String photosOverLimit(int count);

  /// No description provided for @generalNotes.
  ///
  /// In es, this message translates to:
  /// **'Observaciones generales'**
  String get generalNotes;

  /// No description provided for @submitVerification.
  ///
  /// In es, this message translates to:
  /// **'Enviar verificación'**
  String get submitVerification;

  /// No description provided for @done.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get done;

  /// No description provided for @photoFromCamera.
  ///
  /// In es, this message translates to:
  /// **'Sacar foto'**
  String get photoFromCamera;

  /// No description provided for @photoFromGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get photoFromGallery;

  /// No description provided for @photoRequired.
  ///
  /// In es, this message translates to:
  /// **'Foto obligatoria'**
  String get photoRequired;

  /// No description provided for @photosCount.
  ///
  /// In es, this message translates to:
  /// **'{count} de {max} fotos'**
  String photosCount(int count, int max);

  /// No description provided for @photos.
  ///
  /// In es, this message translates to:
  /// **'Fotos'**
  String get photos;

  /// No description provided for @noDailyLogs.
  ///
  /// In es, this message translates to:
  /// **'Todavía no cargaste bitácoras'**
  String get noDailyLogs;

  /// No description provided for @noVerifications.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hiciste verificaciones'**
  String get noVerifications;

  /// No description provided for @noReceivedReports.
  ///
  /// In es, this message translates to:
  /// **'No recibiste informes'**
  String get noReceivedReports;

  /// No description provided for @noIncidents.
  ///
  /// In es, this message translates to:
  /// **'No hay incidencias'**
  String get noIncidents;

  /// No description provided for @noRequirements.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes'**
  String get noRequirements;

  /// No description provided for @reviewApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get reviewApproved;

  /// No description provided for @reviewObserved.
  ///
  /// In es, this message translates to:
  /// **'Observado'**
  String get reviewObserved;

  /// No description provided for @reviewPending.
  ///
  /// In es, this message translates to:
  /// **'Sin revisar'**
  String get reviewPending;

  /// No description provided for @typeDailyLog.
  ///
  /// In es, this message translates to:
  /// **'Bitácora'**
  String get typeDailyLog;

  /// No description provided for @typeReport.
  ///
  /// In es, this message translates to:
  /// **'Informe'**
  String get typeReport;

  /// No description provided for @typeIncident.
  ///
  /// In es, this message translates to:
  /// **'Incidencia'**
  String get typeIncident;

  /// No description provided for @typeAssetAudit.
  ///
  /// In es, this message translates to:
  /// **'Auditoría de ítem'**
  String get typeAssetAudit;

  /// No description provided for @typeVerification.
  ///
  /// In es, this message translates to:
  /// **'Verificación'**
  String get typeVerification;

  /// No description provided for @typeMovementChecklist.
  ///
  /// In es, this message translates to:
  /// **'Checklist de movimiento'**
  String get typeMovementChecklist;

  /// No description provided for @whatDidYouDoToday.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hiciste hoy?'**
  String get whatDidYouDoToday;

  /// No description provided for @tasks.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get tasks;

  /// No description provided for @addTask.
  ///
  /// In es, this message translates to:
  /// **'Agregar tarea'**
  String get addTask;

  /// No description provided for @incidentTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get incidentTitle;

  /// No description provided for @kind.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get kind;

  /// No description provided for @severityLabel.
  ///
  /// In es, this message translates to:
  /// **'Gravedad'**
  String get severityLabel;

  /// No description provided for @relatedItem.
  ///
  /// In es, this message translates to:
  /// **'Ítem (opcional)'**
  String get relatedItem;

  /// No description provided for @noItemSelected.
  ///
  /// In es, this message translates to:
  /// **'Ninguno: tocá para escanear o buscar'**
  String get noItemSelected;

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @incidentMissing.
  ///
  /// In es, this message translates to:
  /// **'Faltante'**
  String get incidentMissing;

  /// No description provided for @incidentDamage.
  ///
  /// In es, this message translates to:
  /// **'Daño'**
  String get incidentDamage;

  /// No description provided for @incidentLoss.
  ///
  /// In es, this message translates to:
  /// **'Pérdida'**
  String get incidentLoss;

  /// No description provided for @incidentClaim.
  ///
  /// In es, this message translates to:
  /// **'Reclamo'**
  String get incidentClaim;

  /// No description provided for @incidentOther.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get incidentOther;

  /// No description provided for @severityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get severityLow;

  /// No description provided for @severityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get severityHigh;

  /// No description provided for @severityCritical.
  ///
  /// In es, this message translates to:
  /// **'Crítica'**
  String get severityCritical;

  /// No description provided for @incidentOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get incidentOpen;

  /// No description provided for @incidentInvestigating.
  ///
  /// In es, this message translates to:
  /// **'En análisis'**
  String get incidentInvestigating;

  /// No description provided for @incidentResolved.
  ///
  /// In es, this message translates to:
  /// **'Resuelta'**
  String get incidentResolved;

  /// No description provided for @incidentClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get incidentClosed;

  /// No description provided for @reqNewItems.
  ///
  /// In es, this message translates to:
  /// **'Ítems nuevos'**
  String get reqNewItems;

  /// No description provided for @reqWriteOff.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get reqWriteOff;

  /// No description provided for @reqRepair.
  ///
  /// In es, this message translates to:
  /// **'Reparación'**
  String get reqRepair;

  /// No description provided for @reqPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get reqPending;

  /// No description provided for @reqInTransfer.
  ///
  /// In es, this message translates to:
  /// **'En traslado'**
  String get reqInTransfer;

  /// No description provided for @reqInPurchase.
  ///
  /// In es, this message translates to:
  /// **'En compra'**
  String get reqInPurchase;

  /// No description provided for @reqDelivered.
  ///
  /// In es, this message translates to:
  /// **'Entregada'**
  String get reqDelivered;

  /// No description provided for @reqRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get reqRejected;

  /// No description provided for @reqCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get reqCancelled;

  /// No description provided for @describeItem.
  ///
  /// In es, this message translates to:
  /// **'Describí qué necesitás'**
  String get describeItem;

  /// No description provided for @quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get quantity;

  /// No description provided for @addProjectItem.
  ///
  /// In es, this message translates to:
  /// **'Agregar ítem del proyecto'**
  String get addProjectItem;

  /// No description provided for @fromCatalog.
  ///
  /// In es, this message translates to:
  /// **'Del catálogo'**
  String get fromCatalog;

  /// No description provided for @otherItem.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get otherItem;

  /// No description provided for @neededByOptional.
  ///
  /// In es, this message translates to:
  /// **'Para cuándo (opcional)'**
  String get neededByOptional;

  /// No description provided for @checkInTitle.
  ///
  /// In es, this message translates to:
  /// **'Subida y bajada'**
  String get checkInTitle;

  /// No description provided for @confirmCheckUp.
  ///
  /// In es, this message translates to:
  /// **'¿Registrar la subida de {name}?'**
  String confirmCheckUp(String name);

  /// No description provided for @confirmCheckDown.
  ///
  /// In es, this message translates to:
  /// **'¿Registrar la bajada de {name}?'**
  String confirmCheckDown(String name);

  /// No description provided for @checkInTimeNote.
  ///
  /// In es, this message translates to:
  /// **'Queda registrada a las {time} (hora del teléfono).'**
  String checkInTimeNote(String time);

  /// No description provided for @youAreOnSite.
  ///
  /// In es, this message translates to:
  /// **'Estás arriba'**
  String get youAreOnSite;

  /// No description provided for @youAreOffSite.
  ///
  /// In es, this message translates to:
  /// **'Estás abajo'**
  String get youAreOffSite;

  /// No description provided for @registerUp.
  ///
  /// In es, this message translates to:
  /// **'Registrar subida'**
  String get registerUp;

  /// No description provided for @registerDown.
  ///
  /// In es, this message translates to:
  /// **'Registrar bajada'**
  String get registerDown;

  /// No description provided for @myCheckIns.
  ///
  /// In es, this message translates to:
  /// **'Mis marcaciones'**
  String get myCheckIns;

  /// No description provided for @wentUp.
  ///
  /// In es, this message translates to:
  /// **'Subida'**
  String get wentUp;

  /// No description provided for @wentDown.
  ///
  /// In es, this message translates to:
  /// **'Bajada'**
  String get wentDown;

  /// No description provided for @otherPeople.
  ///
  /// In es, this message translates to:
  /// **'Otras personas'**
  String get otherPeople;

  /// No description provided for @noEmployees.
  ///
  /// In es, this message translates to:
  /// **'No hay personas para mostrar'**
  String get noEmployees;

  /// No description provided for @onSiteRequiredTitle.
  ///
  /// In es, this message translates to:
  /// **'Primero registrá tu subida'**
  String get onSiteRequiredTitle;

  /// No description provided for @onSiteRequiredBody.
  ///
  /// In es, this message translates to:
  /// **'Para hacer esto en {project} tenés que figurar arriba. ¿Registramos tu subida ahora? Se envía antes que lo demás.'**
  String onSiteRequiredBody(String project);

  /// No description provided for @registerUpAndContinue.
  ///
  /// In es, this message translates to:
  /// **'Registrar subida y seguir'**
  String get registerUpAndContinue;

  /// No description provided for @newItem.
  ///
  /// In es, this message translates to:
  /// **'Nuevo ítem'**
  String get newItem;

  /// No description provided for @createItem.
  ///
  /// In es, this message translates to:
  /// **'Dar de alta'**
  String get createItem;

  /// No description provided for @chooseModel.
  ///
  /// In es, this message translates to:
  /// **'Elegí el modelo'**
  String get chooseModel;

  /// No description provided for @searchModels.
  ///
  /// In es, this message translates to:
  /// **'Buscar modelo o marca'**
  String get searchModels;

  /// No description provided for @noModels.
  ///
  /// In es, this message translates to:
  /// **'No hay modelos. Se cargan desde la web.'**
  String get noModels;

  /// No description provided for @codes.
  ///
  /// In es, this message translates to:
  /// **'Códigos'**
  String get codes;

  /// No description provided for @barcodeOptional.
  ///
  /// In es, this message translates to:
  /// **'Código de barras del fabricante (opcional)'**
  String get barcodeOptional;

  /// No description provided for @serialNumberOptional.
  ///
  /// In es, this message translates to:
  /// **'N° de serie (opcional)'**
  String get serialNumberOptional;

  /// No description provided for @serialRequired.
  ///
  /// In es, this message translates to:
  /// **'Exige n° de serie'**
  String get serialRequired;

  /// No description provided for @custodyRequired.
  ///
  /// In es, this message translates to:
  /// **'Lleva responsable'**
  String get custodyRequired;

  /// No description provided for @vehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get vehicle;

  /// No description provided for @container.
  ///
  /// In es, this message translates to:
  /// **'Contenedor'**
  String get container;

  /// No description provided for @vehicleData.
  ///
  /// In es, this message translates to:
  /// **'Datos del vehículo'**
  String get vehicleData;

  /// No description provided for @chassisNumber.
  ///
  /// In es, this message translates to:
  /// **'N° de chasis'**
  String get chassisNumber;

  /// No description provided for @engineNumber.
  ///
  /// In es, this message translates to:
  /// **'N° de motor'**
  String get engineNumber;

  /// No description provided for @year.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get year;

  /// No description provided for @initialLocation.
  ///
  /// In es, this message translates to:
  /// **'Dónde queda'**
  String get initialLocation;

  /// No description provided for @chooseLocation.
  ///
  /// In es, this message translates to:
  /// **'Elegí dónde queda'**
  String get chooseLocation;

  /// No description provided for @companyLocation.
  ///
  /// In es, this message translates to:
  /// **'de la empresa'**
  String get companyLocation;

  /// No description provided for @me.
  ///
  /// In es, this message translates to:
  /// **'yo'**
  String get me;

  /// No description provided for @custodianRequired.
  ///
  /// In es, this message translates to:
  /// **'Elegí el responsable'**
  String get custodianRequired;

  /// No description provided for @descriptionOptional.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get descriptionOptional;

  /// No description provided for @codeAlreadyUsed.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un ítem con el código {code}'**
  String codeAlreadyUsed(String code);

  /// No description provided for @createWithThisCode.
  ///
  /// In es, this message translates to:
  /// **'Dar de alta un ítem con este código'**
  String get createWithThisCode;

  /// No description provided for @scanCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanear código'**
  String get scanCodeTitle;

  /// No description provided for @opCreateAsset.
  ///
  /// In es, this message translates to:
  /// **'Alta de {code}'**
  String opCreateAsset(String code);

  /// No description provided for @fixCode.
  ///
  /// In es, this message translates to:
  /// **'Corregir código'**
  String get fixCode;

  /// No description provided for @fixCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Otro código interno'**
  String get fixCodeTitle;

  /// No description provided for @catTool.
  ///
  /// In es, this message translates to:
  /// **'Herramienta'**
  String get catTool;

  /// No description provided for @catVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get catVehicle;

  /// No description provided for @catEpp.
  ///
  /// In es, this message translates to:
  /// **'EPP'**
  String get catEpp;

  /// No description provided for @catTechEquipment.
  ///
  /// In es, this message translates to:
  /// **'Equipo tecnológico'**
  String get catTechEquipment;

  /// No description provided for @catToolbox.
  ///
  /// In es, this message translates to:
  /// **'Caja de herramientas'**
  String get catToolbox;

  /// No description provided for @catCableAccessory.
  ///
  /// In es, this message translates to:
  /// **'Cables y accesorios'**
  String get catCableAccessory;

  /// No description provided for @catConsumable.
  ///
  /// In es, this message translates to:
  /// **'Consumible'**
  String get catConsumable;

  /// No description provided for @catInstrument.
  ///
  /// In es, this message translates to:
  /// **'Instrumento'**
  String get catInstrument;

  /// No description provided for @catEquipment.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get catEquipment;

  /// No description provided for @catClothing.
  ///
  /// In es, this message translates to:
  /// **'Indumentaria'**
  String get catClothing;

  /// No description provided for @identifierLabel.
  ///
  /// In es, this message translates to:
  /// **'Email o DNI/CUIL'**
  String get identifierLabel;

  /// No description provided for @identifierHint.
  ///
  /// In es, this message translates to:
  /// **'nombre@empresa.com o 30111222'**
  String get identifierHint;

  /// No description provided for @invalidIdentifier.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un email o un DNI/CUIL'**
  String get invalidIdentifier;

  /// No description provided for @secretLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña o PIN'**
  String get secretLabel;

  /// No description provided for @sectionProject.
  ///
  /// In es, this message translates to:
  /// **'En el proyecto'**
  String get sectionProject;

  /// No description provided for @sectionLogistics.
  ///
  /// In es, this message translates to:
  /// **'Logística'**
  String get sectionLogistics;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @changePin.
  ///
  /// In es, this message translates to:
  /// **'Cambiar PIN'**
  String get changePin;

  /// No description provided for @switchCompany.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de empresa'**
  String get switchCompany;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'El del teléfono'**
  String get languageSystem;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar la sesión en este teléfono?'**
  String get logoutConfirm;

  /// No description provided for @logoutWithPending.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay 1 acción sin enviar: si cerrás la sesión se pierde.} other{Hay {count} acciones sin enviar: si cerrás la sesión se pierden.}}'**
  String logoutWithPending(int count);

  /// No description provided for @pendingBlocksSwitch.
  ///
  /// In es, this message translates to:
  /// **'Primero tienen que enviarse las acciones pendientes'**
  String get pendingBlocksSwitch;

  /// No description provided for @dniValue.
  ///
  /// In es, this message translates to:
  /// **'DNI {dni}'**
  String dniValue(String dni);

  /// No description provided for @currentPin.
  ///
  /// In es, this message translates to:
  /// **'PIN actual'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In es, this message translates to:
  /// **'PIN nuevo'**
  String get newPin;

  /// No description provided for @repeatPin.
  ///
  /// In es, this message translates to:
  /// **'Repetí el PIN nuevo'**
  String get repeatPin;

  /// No description provided for @pinTooShort.
  ///
  /// In es, this message translates to:
  /// **'Entre 4 y 8 dígitos'**
  String get pinTooShort;

  /// No description provided for @pinMismatch.
  ///
  /// In es, this message translates to:
  /// **'No coinciden'**
  String get pinMismatch;

  /// No description provided for @pinChanged.
  ///
  /// In es, this message translates to:
  /// **'PIN cambiado'**
  String get pinChanged;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
