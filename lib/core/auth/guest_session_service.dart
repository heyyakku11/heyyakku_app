import 'package:yakku/core/auth/guest_token_store.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/background/background_job.dart';
import 'package:yakku/data/datasources/guest_remote_data_source.dart';
import 'package:yakku/data/models/guest/guest_response.dart';

/// Coordinates anonymous guest profile creation via [BackgroundApiWorker].
class GuestSessionService {
  GuestSessionService({
    required this._guestRemote,
    required this._guestTokenStore,
    required this._worker,
  });

  static const jobId = 'createGuest';
  static const jobType = 'createGuest';

  final GuestRemoteDataSource _guestRemote;
  final GuestTokenStore _guestTokenStore;
  final BackgroundApiWorker _worker;

  /// Fire-and-forget create-guest. No-op when a valid guest token already exists.
  void ensureGuestProfileInBackground() {
    if (_guestTokenStore.hasValidGuest) return;

    _worker.enqueue(
      BackgroundJob(
        id: jobId,
        type: jobType,
        maxRetries: 2,
        execute: _createAndPersist,
      ),
    );
  }

  Future<Object?> _createAndPersist() async {
    final GuestResponse response = await _guestRemote.createGuest();
    await _guestTokenStore.saveFromResponse(response);
    return response;
  }
}
