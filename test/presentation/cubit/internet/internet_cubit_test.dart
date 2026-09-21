import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/network/internet_connection_service.dart';
import 'package:yakku/core/network/internet_status.dart';
import 'package:yakku/presentation/cubit/internet/internet_cubit.dart';

class _FakeInternetConnectionService implements InternetConnectionService {
  _FakeInternetConnectionService({required bool initiallyConnected})
    : _connected = initiallyConnected;

  bool _connected;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool disposed = false;
  int refreshCount = 0;

  void emit(bool connected) {
    _connected = connected;
    _controller.add(connected);
  }

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Stream<bool> get onStatusChanged => _controller.stream;

  @override
  Future<void> refresh() async {
    refreshCount++;
    _controller.add(_connected);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}

void main() {
  group('InternetCubit', () {
    test('initialize online sets InternetStatus.online', () async {
      final service = _FakeInternetConnectionService(initiallyConnected: true);
      final cubit = InternetCubit(service);

      await cubit.initialize();

      expect(cubit.state, InternetStatus.online);
      await cubit.close();
    });

    test('initialize offline sets InternetStatus.offline', () async {
      final service = _FakeInternetConnectionService(initiallyConnected: false);
      final cubit = InternetCubit(service);

      await cubit.initialize();

      expect(cubit.state, InternetStatus.offline);
      await cubit.close();
    });

    test('online to offline transition', () async {
      final service = _FakeInternetConnectionService(initiallyConnected: true);
      final cubit = InternetCubit(service);
      await cubit.initialize();

      final states = <InternetStatus>[];
      final sub = cubit.stream.listen(states.add);

      service.emit(false);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, InternetStatus.offline);
      expect(states, [InternetStatus.offline]);

      await sub.cancel();
      await cubit.close();
    });

    test('offline to online transition', () async {
      final service = _FakeInternetConnectionService(initiallyConnected: false);
      final cubit = InternetCubit(service);
      await cubit.initialize();

      final states = <InternetStatus>[];
      final sub = cubit.stream.listen(states.add);

      service.emit(true);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, InternetStatus.online);
      expect(states, [InternetStatus.online]);

      await sub.cancel();
      await cubit.close();
    });

    test('duplicate online values do not re-emit', () async {
      final service = _FakeInternetConnectionService(initiallyConnected: true);
      final cubit = InternetCubit(service);
      await cubit.initialize();

      final states = <InternetStatus>[];
      final sub = cubit.stream.listen(states.add);

      service.emit(true);
      service.emit(true);
      service.emit(true);
      await Future<void>.delayed(Duration.zero);

      expect(states, isEmpty);
      expect(cubit.state, InternetStatus.online);

      await sub.cancel();
      await cubit.close();
    });

    test('close cancels subscription and disposes service', () async {
      final service = _FakeInternetConnectionService(initiallyConnected: true);
      final cubit = InternetCubit(service);
      await cubit.initialize();

      await cubit.close();

      expect(service.disposed, isTrue);
      expect(cubit.isClosed, isTrue);
    });

    test('refresh delegates to the service', () async {
      final service = _FakeInternetConnectionService(initiallyConnected: true);
      final cubit = InternetCubit(service);
      await cubit.initialize();

      await cubit.refresh();

      expect(service.refreshCount, 1);
      await cubit.close();
    });
  });
}
