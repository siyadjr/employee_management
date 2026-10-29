import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class INetworkInfo {
  Stream<bool> get onConnectivityChanged;
  Future<bool> get isConnected;
}

class NetworkInfo implements INetworkInfo {
  final Connectivity _connectivity;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  NetworkInfo({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  @override
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasValidConnection(results);
    } catch (_) {
      return true; // Fallback gracefully if platform channel is not active
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _connectivityController.add(_hasValidConnection(results));
  }

  bool _hasValidConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }

  void dispose() {
    _connectivityController.close();
  }
}

class MockNetworkInfo implements INetworkInfo {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool connected;

  MockNetworkInfo({this.connected = true});

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isConnected async => connected;

  void setConnected(bool value) {
    connected = value;
    _controller.add(value);
  }
}
