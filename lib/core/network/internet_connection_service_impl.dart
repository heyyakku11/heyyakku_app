import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart'
    hide InternetStatus;
import 'package:yakku/core/network/internet_connection_service.dart';

/// Concrete internet monitor.
///
/// Uses [Connectivity] for link changes and [InternetConnection] for actual
/// reachability. Does not poll on a timer — checks run on connectivity events
/// and explicit [refresh] calls only.
class InternetConnectionServiceImpl implements InternetConnectionService {
  InternetConnectionServiceImpl({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
    this._connectivityStream,
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Future<bool> Function()? hasInternetAccess,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetConnection =
            internetConnection ?? InternetConnection.createInstance(),
        _checkConnectivityOverride = checkConnectivity,
        _hasInternetAccessOverride = hasInternetAccess {
    _subscription = (_connectivityStream ?? _connectivity.onConnectivityChanged)
        .listen(_onConnectivityChanged);
    _log('Internet monitoring initialized');
  }

  final Connectivity _connectivity;
  final InternetConnection _internetConnection;
  final Stream<List<ConnectivityResult>>? _connectivityStream;
  final Future<List<ConnectivityResult>> Function()? _checkConnectivityOverride;
  final Future<bool> Function()? _hasInternetAccessOverride;

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _lastEmitted;
  int _checkGeneration = 0;
  bool _disposed = false;

  @override
  Stream<bool> get onStatusChanged => _controller.stream;

  @override
  Future<bool> get isConnected async {
    if (_disposed) return false;
    final results = await _readConnectivity();
    if (_hasNoLink(results)) return false;
    return _probeInternet();
  }

  @override
  Future<void> refresh() async {
    if (_disposed) return;
    final results = await _readConnectivity();
    await _evaluate(results);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _checkGeneration++;
    await _subscription?.cancel();
    _subscription = null;
    await _controller.close();
    await _internetConnection.dispose();
    _log('Internet monitoring disposed');
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    if (_disposed) return;
    await _evaluate(results);
  }

  Future<void> _evaluate(List<ConnectivityResult> results) async {
    if (_disposed) return;

    if (_hasNoLink(results)) {
      _emit(false);
      return;
    }

    final generation = ++_checkGeneration;
    final online = await _probeInternet();
    if (_disposed || generation != _checkGeneration) return;
    _emit(online);
  }

  Future<List<ConnectivityResult>> _readConnectivity() {
    final override = _checkConnectivityOverride;
    if (override != null) {
      return override();
    }
    return _connectivity.checkConnectivity();
  }

  Future<bool> _probeInternet() async {
    try {
      final override = _hasInternetAccessOverride;
      if (override != null) {
        return await override();
      }
      return await _internetConnection.hasInternetAccess;
    } catch (error) {
      _log('Internet reachability check failed: $error');
      return false;
    }
  }

  bool _hasNoLink(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((result) => result == ConnectivityResult.none);
  }

  void _emit(bool online) {
    if (_disposed || _controller.isClosed) return;
    if (_lastEmitted == online) return;
    _lastEmitted = online;
    _controller.add(online);
    _log(
      'Internet status changed: ${online ? 'ONLINE' : 'OFFLINE'}',
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
