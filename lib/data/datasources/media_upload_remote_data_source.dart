import 'dart:typed_data';

import 'package:yakku/data/models/media/complete_media_upload_request.dart';
import 'package:yakku/data/models/media/create_media_upload_session_request.dart';
import 'package:yakku/data/models/media/media_upload_session_response.dart';

abstract interface class MediaUploadRemoteDataSource {
  Future<MediaUploadSessionResponse> createSession(
    CreateMediaUploadSessionRequest request,
  );

  Future<void> uploadBytes({
    required MediaUploadTargetResponse target,
    required Uint8List bytes,
  });

  Future<MediaUploadSessionResponse> completeSession({
    required String sessionId,
    required CompleteMediaUploadRequest request,
  });

  Future<void> cancelSession(String sessionId);
}
