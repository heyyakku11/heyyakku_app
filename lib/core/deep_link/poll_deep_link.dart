import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/core/router/app_routes.dart';

/// Parses the canonical shared-poll link `https://<web host>/vote/{pollId}`.
///
/// The OS only hands the app links for the verified host and `/vote/` prefix
/// (see AndroidManifest.xml / Associated Domains); this is the second,
/// in-app line of validation. Query strings and fragments are never trusted.
abstract final class PollDeepLink {
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Query parameter carrying the post-onboarding destination.
  static const returnToParam = 'from';

  static bool isValidPollId(String? value) =>
      value != null && _uuid.hasMatch(value);

  /// Returns the lower-cased poll id for a full shared-poll URL, or `null`
  /// for any other host, scheme, path shape or malformed id.
  static String? pollIdFromUrl(
    Uri uri, {
    String webBaseUrl = ApiConstants.webBaseUrl,
  }) {
    final base = Uri.tryParse(webBaseUrl);
    if (base == null) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (uri.host.toLowerCase() != base.host.toLowerCase()) return null;
    return _pollIdFromSegments(uri.pathSegments);
  }

  /// Same as [pollIdFromUrl] for an in-app location such as `/vote/{id}`
  /// (go_router drops scheme and host for incoming links).
  static String? pollIdFromPath(Uri location) =>
      _pollIdFromSegments(location.pathSegments);

  static String? _pollIdFromSegments(List<String> segments) {
    final parts = segments.where((s) => s.isNotEmpty).toList(growable: false);
    if (parts.length != 2 || parts.first != 'vote') return null;
    final id = parts[1];
    return isValidPollId(id) ? id.toLowerCase() : null;
  }

  /// A return-to value is only honoured when it is an in-app shared-poll path.
  static String? safeReturnPath(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    final id = pollIdFromPath(uri);
    return id == null ? null : AppRoutes.pollVoteLocation(id);
  }
}
