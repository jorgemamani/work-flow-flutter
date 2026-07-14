/// Notifica globalmente cuando la sesión expiró (HTTP 401).
/// El [AuthBloc] se suscribe en el arranque de la app.
class SessionExpiredHandler {
  SessionExpiredHandler._();

  static final SessionExpiredHandler instance = SessionExpiredHandler._();

  void Function()? onSessionExpired;

  bool _isHandling = false;

  Future<void> notify() async {
    if (_isHandling) return;
    _isHandling = true;
    try {
      onSessionExpired?.call();
    } finally {
      _isHandling = false;
    }
  }
}
