import 'dart:async';

import 'package:yakku/core/network/internet_connection_service.dart';

/// Always-online fake used by widget tests to avoid platform plugins.
class FakeOnlineInternetConnectionService implements InternetConnectionService {
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onStatusChanged => _controller.stream;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
