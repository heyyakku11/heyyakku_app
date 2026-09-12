import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakku/core/network/internet_connection_service.dart';
import 'package:yakku/core/network/internet_status.dart';

/// Global cubit exposing application [InternetStatus].
///
/// Future offline sync can listen for `offline → online` transitions via
/// [BlocListener] or by observing state changes on this cubit.
class InternetCubit extends Cubit<InternetStatus> {
  InternetCubit(this._internetConnectionService)
      : super(InternetStatus.offline);

  final InternetConnectionService _internetConnectionService;
  StreamSubscription<bool>? _subscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || isClosed) return;
    _initialized = true;

    final connected = await _internetConnectionService.isConnected;
    if (isClosed) return;
    _emitStatus(connected);

    _subscription = _internetConnectionService.onStatusChanged.listen(
      (connected) {
        if (isClosed) return;
        _emitStatus(connected);
      },
    );
  }

  Future<void> refresh() => _internetConnectionService.refresh();

  void _emitStatus(bool connected) {
    final next = connected ? InternetStatus.online : InternetStatus.offline;
    if (state == next) return;
    emit(next);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    await _internetConnectionService.dispose();
    return super.close();
  }
}
