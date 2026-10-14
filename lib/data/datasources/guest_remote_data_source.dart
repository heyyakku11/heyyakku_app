import 'package:yakku/data/models/guest/guest_response.dart';

abstract interface class GuestRemoteDataSource {
  /// Creates or reuses an anonymous guest session.
  ///
  /// When a new token is issued, [GuestResponse.guestToken] is non-null and
  /// should be stored and sent as `X-Guest-Token` on media APIs.
  Future<GuestResponse> createGuest();
}
