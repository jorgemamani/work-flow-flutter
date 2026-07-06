class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Shell (tabs)
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String bitacora = '/bitacora';

  // Sub-rutas de inventario (path completo para context.push/go)
  static const String assetForm = '/inventory/form';
  static const String assetDetail = '/inventory/detail';

  // Cuenta (accesible desde el drawer)
  static const String account = '/account';
}
