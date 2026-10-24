abstract final class RouteNames {
  static const splash = '/';
  static const login = '/login';
  static const selectTenant = '/select-tenant';

  // Pestañas
  static const home = '/home';
  static const items = '/items';
  static const records = '/records';
  static const account = '/account';

  // Pantallas sobre las pestañas
  static const scan = '/scan';
  static const item = '/item';
  static const incomingRemitos = '/remitos/incoming';
  static const remito = '/remito';
  static const returnRemito = '/remitos/return';
  static const newVerification = '/verifications/new';
  static const newDailyLog = '/daily-logs/new';
  static const newIncident = '/incidents/new';
  static const newRequirement = '/requirements/new';
  static const checkIn = '/check-in';
  static const newItem = '/items/new';
  static const sync = '/sync';
  static const changePin = '/account/pin';

  static String itemDetail(String id) => '$item/$id';
  static String newItemWith({String? code, String? barcode}) => Uri(
        path: newItem,
        queryParameters: {
          if (code != null) 'code': code,
          if (barcode != null) 'barcode': barcode,
        },
      ).toString();
  static String moveItem(String id) => '$item/$id/move';
  static String changeStatus(String id) => '$item/$id/status';
  static String receiveRemito(String id) => '$remito/$id/receive';
}
