import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// ¿Hay red? Combina el estado del sistema con un "modo sin conexión"
/// manual (para trabajar sin gastar datos o para probar el modo offline).
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _hasNetwork = true;
  bool _simulatedOffline = false;

  bool get isOnline => _hasNetwork && !_simulatedOffline;
  bool get simulatedOffline => _simulatedOffline;

  /// Emite cada vez que cambia [isOnline].
  Stream<bool> get onlineChanges => _controller.stream;

  Future<void> start({required bool simulatedOffline}) async {
    _simulatedOffline = simulatedOffline;
    try {
      _hasNetwork = _isConnected(await _connectivity.checkConnectivity());
    } catch (_) {
      _hasNetwork = true;
    }
    _sub = _connectivity.onConnectivityChanged.listen((r) {
      final was = isOnline;
      _hasNetwork = _isConnected(r);
      if (was != isOnline) _controller.add(isOnline);
    });
  }

  void setSimulatedOffline(bool value) {
    final was = isOnline;
    _simulatedOffline = value;
    if (was != isOnline) _controller.add(isOnline);
  }

  static bool _isConnected(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
