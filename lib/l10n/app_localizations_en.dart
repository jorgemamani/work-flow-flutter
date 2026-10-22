// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabItems => 'Items';

  @override
  String get tabRecords => 'Records';

  @override
  String get tabAccount => 'Account';

  @override
  String get tabDailyLogs => 'Daily logs';

  @override
  String get tabVerifications => 'Verifications';

  @override
  String get tabIncidents => 'Incidents';

  @override
  String get tabRequirements => 'Requests';

  @override
  String get loginField => 'Field';

  @override
  String get loginOffice => 'Office';

  @override
  String get companyCuit => 'Company CUIT';

  @override
  String get companyCuitOptional => 'Company CUIT (optional)';

  @override
  String get invalidCuit => 'CUIT must have 11 digits';

  @override
  String get documentNumber => 'ID number (DNI or CUIL)';

  @override
  String get pin => 'PIN';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get requiredField => 'Required';

  @override
  String get loginOffline =>
      'No connection. Signing in for the first time needs a signal.';

  @override
  String get loginHelp => 'Forgot your PIN? Ask your company to reset it.';

  @override
  String get sessionExpiredKeepQueue =>
      'Your session expired. Sign in again: what you recorded offline is kept and will be sent afterwards.';

  @override
  String get chooseCompany => 'Choose a company';

  @override
  String get chooseCompanyHelp =>
      'You work for more than one company. Which one do you want to use?';

  @override
  String helloName(String name) {
    return 'Hi, $name';
  }

  @override
  String get noProject =>
      'You have no assigned project. Once you are assigned one, it shows up here after syncing.';

  @override
  String get noProjectShort => 'No project';

  @override
  String get downloadingProject => 'Downloading project data…';

  @override
  String get changeProject => 'Change project';

  @override
  String get onSite => 'On site';

  @override
  String get offSite => 'Off site';

  @override
  String get quickActions => 'What do you want to do';

  @override
  String get summary => 'Summary';

  @override
  String get actionScan => 'Scan';

  @override
  String get actionReceiveRemito => 'Receive delivery note';

  @override
  String get actionVerification => 'Verification';

  @override
  String get actionDailyLog => 'Daily log';

  @override
  String get actionIncident => 'Incident';

  @override
  String get actionCheckUp => 'Check in';

  @override
  String get actionCheckDown => 'Check out';

  @override
  String get actionRequirement => 'Request';

  @override
  String get actionReturn => 'Return';

  @override
  String get myItems => 'In my charge';

  @override
  String get projectItems => 'In the project';

  @override
  String get receivedReports => 'Received reports';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get offlineWorkingLocally => 'working with the data on the phone';

  @override
  String lastSync(String when) {
    return 'Last sync $when';
  }

  @override
  String get neverSynced => 'Not synced yet';

  @override
  String get allSynced => 'Everything sent';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions waiting to be sent',
      one: '1 action waiting to be sent',
    );
    return '$_temp0';
  }

  @override
  String failedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions failed: check them',
      one: '1 action failed: check it',
    );
    return '$_temp0';
  }

  @override
  String get agoNow => 'just now';

  @override
  String agoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String agoHours(int count) {
    return '$count h ago';
  }

  @override
  String agoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncing => 'Syncing…';

  @override
  String get workOffline => 'Work offline';

  @override
  String get workOfflineHelp =>
      'Does not use the network even with signal. Everything is saved on the phone.';

  @override
  String failedTitle(int count) {
    return 'With problems ($count)';
  }

  @override
  String pendingTitle(int count) {
    return 'Pending, in order ($count)';
  }

  @override
  String get nothingPending => 'Nothing pending';

  @override
  String attempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String get retry => 'Retry';

  @override
  String get discard => 'Discard';

  @override
  String get understood => 'OK';

  @override
  String get redownloadAll => 'Download everything again';

  @override
  String get offlineWillRetry => 'No signal: will retry automatically';

  @override
  String get errorPhotoMissing => 'The photo is no longer on the phone';

  @override
  String get pendingSync => 'Not sent';

  @override
  String get savedQueued => 'Saved. It will be sent when there is signal.';

  @override
  String get savedLocallyHint =>
      'It is saved on the phone with the current time and sent automatically when there is signal.';

  @override
  String get needsConnection => 'This needs a connection';

  @override
  String opMove(String code) {
    return 'Move $code';
  }

  @override
  String opStatus(String code) {
    return 'Change status of $code';
  }

  @override
  String opReception(String number) {
    return 'Receipt of delivery note $number';
  }

  @override
  String get opReturn => 'Return delivery note';

  @override
  String get opReturnSubmit => 'Submit return delivery note';

  @override
  String opVerification(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verification of $count items',
      one: 'Verification of 1 item',
    );
    return '$_temp0';
  }

  @override
  String get opDailyLog => 'Daily log';

  @override
  String opIncident(String title) {
    return 'Incident: $title';
  }

  @override
  String opRequirement(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Request for $count items',
      one: 'Request for 1 item',
    );
    return '$_temp0';
  }

  @override
  String opCheckInUp(String name) {
    return 'Check-in of $name';
  }

  @override
  String opCheckInDown(String name) {
    return 'Check-out of $name';
  }

  @override
  String opPhoto(String what) {
    return 'Photo ($what)';
  }

  @override
  String get searchItems => 'Search by code, model or plate';

  @override
  String get noMyItems => 'You have no items in your charge';

  @override
  String get noProjectItems => 'There are no items in the project';

  @override
  String get consumables => 'Consumables';

  @override
  String get inTransit => 'In transit';

  @override
  String get withPerson => 'With';

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get noCurrentPhoto => 'No current photo';

  @override
  String get inOpenRemito => 'In an open delivery note';

  @override
  String get whereIsIt => 'Where it is';

  @override
  String sinceAgo(String when) {
    return 'Since $when';
  }

  @override
  String get details => 'Details';

  @override
  String get internalCode => 'Internal code';

  @override
  String get barcode => 'Barcode';

  @override
  String get serialNumber => 'Serial number';

  @override
  String get licensePlate => 'License plate';

  @override
  String get category => 'Category';

  @override
  String get custodian => 'Custodian';

  @override
  String get description => 'Description';

  @override
  String contents(int count) {
    return 'Contains ($count)';
  }

  @override
  String get moveItem => 'Move';

  @override
  String get changeStatus => 'Change status';

  @override
  String get reportIncident => 'Report an incident';

  @override
  String get requestRepairOrWriteOff => 'Request repair or write-off';

  @override
  String nowAt(String where) {
    return 'Now at: $where';
  }

  @override
  String get toMyCharge => 'To my charge';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get confirmMove => 'Confirm move';

  @override
  String get status => 'Status';

  @override
  String get condition => 'Condition';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get save => 'Save';

  @override
  String get scanTitle => 'Scan code';

  @override
  String get cameraUnavailable =>
      'Could not open the camera. Type the code below.';

  @override
  String codeNotFound(String code) {
    return 'There is no item with code $code';
  }

  @override
  String get typeCode => 'Or type the code';

  @override
  String get statusOperational => 'Operational';

  @override
  String get statusReserved => 'Reserved';

  @override
  String get statusInRepair => 'In repair';

  @override
  String get statusDamaged => 'Damaged';

  @override
  String get statusLost => 'Lost';

  @override
  String get statusRetired => 'Retired';

  @override
  String get holderLocation => 'Location';

  @override
  String get holderAsset => 'Container or vehicle';

  @override
  String get holderEmployee => 'Person';

  @override
  String get holderInTransit => 'In transit';

  @override
  String get locProjectRoot => 'The mine';

  @override
  String get locWarehouse => 'Warehouse';

  @override
  String get locWorkshop => 'Workshop';

  @override
  String get locOffice => 'Office';

  @override
  String get locCamp => 'Camp';

  @override
  String get locWorkFront => 'Work front';

  @override
  String get locOther => 'Other';

  @override
  String get remitoDraft => 'Draft';

  @override
  String get remitoPendingApproval => 'Pending approval';

  @override
  String get remitoApproved => 'Approved';

  @override
  String get remitoRejected => 'Rejected';

  @override
  String get remitoInTransit => 'In transit';

  @override
  String get remitoReceived => 'Received in full';

  @override
  String get remitoReceivedWithDiff => 'Received with differences';

  @override
  String get remitoControlled => 'Checked';

  @override
  String get remitoCancelled => 'Cancelled';

  @override
  String get remitoTypeShipment => 'Shipment';

  @override
  String get remitoTypeReturn => 'Return';

  @override
  String get remitoTypeTransfer => 'Transfer';

  @override
  String get remitoTypeWorkshop => 'To workshop';

  @override
  String get remitoTypePersonDelivery => 'Delivery to person';

  @override
  String get incomingRemitos => 'Delivery notes to receive';

  @override
  String get noIncomingRemitos =>
      'No delivery notes on their way to this project';

  @override
  String fromTo(String origin, String dest) {
    return '$origin → $dest';
  }

  @override
  String dispatchedAgo(String when) {
    return 'Dispatched $when';
  }

  @override
  String get recentRemitos => 'Recent delivery notes';

  @override
  String get remitoNotFound => 'Delivery note not found';

  @override
  String receiveRemitoTitle(String number) {
    return 'Receive delivery note $number';
  }

  @override
  String get receptionHelp =>
      'Mark each item. Missing: stays in transit and logistics is notified. Damaged: photo required.';

  @override
  String get markReceived => 'Received';

  @override
  String get markMissing => 'Missing';

  @override
  String get markDamaged => 'Damaged';

  @override
  String sentQuantity(String qty) {
    return 'Sent: $qty';
  }

  @override
  String get receivedQuantity => 'Quantity received';

  @override
  String get lessThanSent =>
      'Less than sent: the difference is reported as missing';

  @override
  String get whatHappened => 'What happened? (optional)';

  @override
  String get damagedNeedsPhoto => 'Damaged items need at least one photo';

  @override
  String get confirmReception => 'Confirm receipt';

  @override
  String receptionSummary(int ok, int missing, int damaged) {
    return 'Received: $ok · Missing: $missing · Damaged: $damaged';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get returnRemitoTitle => 'Return delivery note';

  @override
  String get origin => 'Origin';

  @override
  String get destinationWarehouse => 'Destination warehouse';

  @override
  String get itemsToReturn => 'What goes back';

  @override
  String available(String qty) {
    return 'Available: $qty';
  }

  @override
  String createReturn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Create return ($count)',
      one: 'Create return (1)',
      zero: 'Create return',
    );
    return '$_temp0';
  }

  @override
  String get scheduleOptional => 'Schedule (optional)';

  @override
  String get noSchedule => 'No schedule';

  @override
  String photoLimitInfo(int count) {
    return 'Up to $count photos per item';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get chooseItems => 'Choose items';

  @override
  String get chooseItemsToVerify => 'Items to verify';

  @override
  String get verificationEmpty => 'Choose the items you are going to verify';

  @override
  String get requiresPhoto => 'Photo required';

  @override
  String verificationMissingPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items that require a photo have none',
      one: '1 item that requires a photo has none',
    );
    return '$_temp0';
  }

  @override
  String photosOverLimit(int count) {
    return 'At most $count photos per item';
  }

  @override
  String get generalNotes => 'General notes';

  @override
  String get submitVerification => 'Submit verification';

  @override
  String get done => 'Done';

  @override
  String get photoFromCamera => 'Take photo';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get photoRequired => 'Photo required';

  @override
  String photosCount(int count, int max) {
    return '$count of $max photos';
  }

  @override
  String get photos => 'Photos';

  @override
  String get noDailyLogs => 'You have not written any daily logs yet';

  @override
  String get noVerifications => 'You have not done any verifications yet';

  @override
  String get noReceivedReports => 'You have not received any reports';

  @override
  String get noIncidents => 'There are no incidents';

  @override
  String get noRequirements => 'There are no requests';

  @override
  String get reviewApproved => 'Approved';

  @override
  String get reviewObserved => 'Has remarks';

  @override
  String get reviewPending => 'Not reviewed';

  @override
  String get typeDailyLog => 'Daily log';

  @override
  String get typeReport => 'Report';

  @override
  String get typeIncident => 'Incident';

  @override
  String get typeAssetAudit => 'Item audit';

  @override
  String get typeVerification => 'Verification';

  @override
  String get typeMovementChecklist => 'Movement checklist';

  @override
  String get whatDidYouDoToday => 'What did you do today?';

  @override
  String get tasks => 'Tasks';

  @override
  String get addTask => 'Add task';

  @override
  String get incidentTitle => 'Title';

  @override
  String get kind => 'Type';

  @override
  String get severityLabel => 'Severity';

  @override
  String get relatedItem => 'Item (optional)';

  @override
  String get noItemSelected => 'None: tap to scan or search';

  @override
  String get send => 'Send';

  @override
  String get incidentMissing => 'Missing';

  @override
  String get incidentDamage => 'Damage';

  @override
  String get incidentLoss => 'Loss';

  @override
  String get incidentClaim => 'Claim';

  @override
  String get incidentOther => 'Other';

  @override
  String get severityLow => 'Low';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityHigh => 'High';

  @override
  String get severityCritical => 'Critical';

  @override
  String get incidentOpen => 'Open';

  @override
  String get incidentInvestigating => 'Investigating';

  @override
  String get incidentResolved => 'Resolved';

  @override
  String get incidentClosed => 'Closed';

  @override
  String get reqNewItems => 'New items';

  @override
  String get reqWriteOff => 'Write-off';

  @override
  String get reqRepair => 'Repair';

  @override
  String get reqPending => 'Pending';

  @override
  String get reqInTransfer => 'Being transferred';

  @override
  String get reqInPurchase => 'Being purchased';

  @override
  String get reqDelivered => 'Delivered';

  @override
  String get reqRejected => 'Rejected';

  @override
  String get reqCancelled => 'Cancelled';

  @override
  String get describeItem => 'Describe what you need';

  @override
  String get quantity => 'Quantity';

  @override
  String get addProjectItem => 'Add project item';

  @override
  String get fromCatalog => 'From catalog';

  @override
  String get otherItem => 'Other';

  @override
  String get neededByOptional => 'Needed by (optional)';

  @override
  String get checkInTitle => 'Check-in and check-out';

  @override
  String confirmCheckUp(String name) {
    return 'Register check-in of $name?';
  }

  @override
  String confirmCheckDown(String name) {
    return 'Register check-out of $name?';
  }

  @override
  String checkInTimeNote(String time) {
    return 'It is recorded at $time (phone time).';
  }

  @override
  String get youAreOnSite => 'You are on site';

  @override
  String get youAreOffSite => 'You are off site';

  @override
  String get registerUp => 'Check in';

  @override
  String get registerDown => 'Check out';

  @override
  String get myCheckIns => 'My check-ins';

  @override
  String get wentUp => 'Check-in';

  @override
  String get wentDown => 'Check-out';

  @override
  String get otherPeople => 'Other people';

  @override
  String get noEmployees => 'No people to show';

  @override
  String get onSiteRequiredTitle => 'Check in first';

  @override
  String onSiteRequiredBody(String project) {
    return 'To do this at $project you need to be checked in. Register your check-in now? It is sent before everything else.';
  }

  @override
  String get registerUpAndContinue => 'Check in and continue';

  @override
  String get settings => 'Settings';

  @override
  String get changePin => 'Change PIN';

  @override
  String get switchCompany => 'Switch company';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm => 'Sign out on this phone?';

  @override
  String logoutWithPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'There are $count unsent actions: they are lost if you sign out.',
      one: 'There is 1 unsent action: it is lost if you sign out.',
    );
    return '$_temp0';
  }

  @override
  String get pendingBlocksSwitch => 'Pending actions must be sent first';

  @override
  String dniValue(String dni) {
    return 'ID $dni';
  }

  @override
  String get currentPin => 'Current PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get repeatPin => 'Repeat the new PIN';

  @override
  String get pinTooShort => 'Between 4 and 8 digits';

  @override
  String get pinMismatch => 'They do not match';

  @override
  String get pinChanged => 'PIN changed';
}
