import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/network/internet_connection_service_impl.dart';

void main() {
  group('InternetConnectionServiceImpl', () {
    late StreamController<List<ConnectivityResult>> connectivityController;

    tearDown(() async {
      if (!connectivityController.isClosed) {
        await connectivityController.close();
      }
    });

    InternetConnectionServiceImpl createService({
      Future<List<ConnectivityResult>> Function()? checkConnectivity,
      Future<bool> Function()? hasInternetAccess,
    }) {
      connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast();
      return InternetConnectionServiceImpl(
        connectivityStream: connectivityController.stream,
        checkConnectivity: checkConnectivity ??
            () async => const [ConnectivityResult.wifi],
        hasInternetAccess: hasInternetAccess ?? () async => true,
      );
    }

    test('isConnected is false when there is no network link', () async {
      var probeCount = 0;
      final service = createService(
        checkConnectivity: () async => const [ConnectivityResult.none],
        hasInternetAccess: () async {
          probeCount++;
          return true;
        },
      );

      expect(await service.isConnected, isFalse);
      expect(probeCount, 0);

      await service.dispose();
    });

    test('Wi-Fi without reachability reports offline', () async {
      final service = createService(
        hasInternetAccess: () async => false,
      );

      final statuses = <bool>[];
      final sub = service.onStatusChanged.listen(statuses.add);

      await service.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [false]);

      await sub.cancel();
      await service.dispose();
    });

    test('does not emit duplicate consecutive statuses', () async {
      final service = createService();

      final statuses = <bool>[];
      final sub = service.onStatusChanged.listen(statuses.add);

      await service.refresh();
      await service.refresh();
      await service.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [true]);

      await sub.cancel();
      await service.dispose();
    });

    test('connectivity none emits offline without probing internet', () async {
      var probeCount = 0;
      final service = createService(
        hasInternetAccess: () async {
          probeCount++;
          return true;
        },
      );

      final statuses = <bool>[];
      final sub = service.onStatusChanged.listen(statuses.add);

      await service.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(statuses, [true]);
      expect(probeCount, 1);

      connectivityController.add(const [ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [true, false]);
      expect(probeCount, 1);

      await sub.cancel();
      await service.dispose();
    });

    test('ignores stale reachability results after newer checks', () async {
      final completers = <Completer<bool>>[];
      final service = createService(
        hasInternetAccess: () {
          final completer = Completer<bool>();
          completers.add(completer);
          return completer.future;
        },
      );

      final statuses = <bool>[];
      final sub = service.onStatusChanged.listen(statuses.add);

      final firstRefresh = service.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(completers, hasLength(1));

      final secondRefresh = service.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(completers, hasLength(2));

      completers[1].complete(false);
      await secondRefresh;
      await Future<void>.delayed(Duration.zero);

      completers[0].complete(true);
      await firstRefresh;
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [false]);

      await sub.cancel();
      await service.dispose();
    });
  });
}
