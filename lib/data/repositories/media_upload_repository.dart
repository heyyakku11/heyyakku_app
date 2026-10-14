import 'dart:io';
import 'dart:typed_data';

import 'package:yakku/data/datasources/media_upload_remote_data_source.dart';
import 'package:yakku/data/models/media/complete_media_upload_request.dart';
import 'package:yakku/data/models/media/create_media_upload_session_request.dart';
import 'package:yakku/data/models/media/media_upload_session_response.dart';

class MediaUploadRepository {
  MediaUploadRepository(this._remote);

  static const maxImageBytes = 10 * 1024 * 1024;

  final MediaUploadRemoteDataSource _remote;

  /// Uploads an image file and returns the completed session.
  Future<MediaUploadSessionResponse> uploadImageFile({
    required File file,
    required int selectionVersion,
    String? mimeType,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxImageBytes) {
      throw StateError('Photo must be 10 MB or smaller');
    }

    final resolvedMime = _resolveMime(file.path, mimeType);
    final session = await _remote.createSession(
      CreateMediaUploadSessionRequest(
        mediaType: 'image',
        contentType: resolvedMime,
        fileName: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : null,
        fileSize: bytes.length,
        selectionVersion: selectionVersion,
      ),
    );

    final upload = session.upload;
    if (upload == null || upload.url.isEmpty) {
      throw StateError('Upload target missing from session');
    }

    await _remote.uploadBytes(target: upload, bytes: Uint8List.fromList(bytes));

    return _remote.completeSession(
      sessionId: session.sessionId,
      request: CompleteMediaUploadRequest(selectionVersion: selectionVersion),
    );
  }

  String _resolveMime(String path, String? mimeType) {
    final provided = mimeType?.trim().toLowerCase() ?? '';
    if (provided == 'image/jpeg' ||
        provided == 'image/png' ||
        provided == 'image/webp') {
      return provided;
    }

    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
