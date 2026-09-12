/// Abstraction for monitoring actual internet reachability.
///
/// The presentation layer depends on this interface (via [InternetCubit]),
/// not on `connectivity_plus` or reachability packages directly.
abstract interface class InternetConnectionService {
  /// Emits `true` when the device has usable internet, `false` otherwise.
  ///
  /// Only emits when the value changes (no duplicate consecutive values).
  Stream<bool> get onStatusChanged;

  /// Current internet reachability (network link + actual reachability).
  Future<bool> get isConnected;

  /// Re-evaluate reachability (e.g. when the app returns to foreground).
  Future<void> refresh();

  /// Cancel listeners and release resources.
  Future<void> dispose();
}
