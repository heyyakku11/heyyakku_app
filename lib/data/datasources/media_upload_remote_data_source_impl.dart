import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/media_upload_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/media/complete_media_upload_request.dart';
import 'package:yakku/data/models/media/create_media_upload_session_request.dart';
import 'package:yakku/data/models/media/media_upload_session_response.dart';

class MediaUploadRemoteDataSourceImpl implements MediaUploadRemoteDataSource {
  MediaUploadRemoteDataSourceImpl({
    required this.apiDio,
    Dio? storageDio,
  }) : storageDio = storageDio ?? Dio();

  /// Authenticated API client.
  final Dio apiDio;

  /// Plain client for presigned storage PUTs (no auth interceptor).
  final Dio storageDio;

  @override
  Future<MediaUploadSessionResponse> createSession(
    CreateMediaUploadSessionRequest request,
  ) async {
    final response = await apiDio.post<Map<String, dynamic>>(
      ApiRoutes.mediaUploadSessions,
      data: request.toJson(),
    );

    return _unwrap(
      response.data,
      emptyMessage: 'Empty media upload session response',
      failureMessage: 'Could not create upload session',
    );
  }

  @override
  Future<void> uploadBytes({
    required MediaUploadTargetResponse target,
    required Uint8List bytes,
  }) async {
    if (target.url.isEmpty) {
      throw StateError('Missing upload URL');
    }

    final method = target.method.trim().toUpperCase();
    final headers = Map<String, dynamic>.from(target.headers);
    final signedContentType =
        headers.remove('Content-Type') ?? headers.remove('content-type');
    // Presigned URLs require the signed Content-Type (and other headers) verbatim.
    final options = Options(
      headers: headers,
      contentType: signedContentType?.toString(),
    );

    final Response<dynamic> response;
    if (method == 'PUT' || method.isEmpty) {
      response = await storageDio.put<dynamic>(
        target.url,
        data: bytes,
        options: options,
      );
    } else if (method == 'POST') {
      response = await storageDio.post<dynamic>(
        target.url,
        data: bytes,
        options: options,
      );
    } else {
      throw StateError('Unsupported upload method: $method');
    }

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw StateError('Upload failed with status $status');
    }
  }

  @override
  Future<MediaUploadSessionResponse> completeSession({
    required String sessionId,
    required CompleteMediaUploadRequest request,
  }) async {
    final response = await apiDio.post<Map<String, dynamic>>(
      ApiRoutes.mediaUploadSessionComplete(sessionId),
      data: request.toJson(),
    );

    return _unwrap(
      response.data,
      emptyMessage: 'Empty complete upload response',
      failureMessage: 'Could not complete upload',
    );
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    await apiDio.post<void>(ApiRoutes.mediaUploadSessionCancel(sessionId));
  }

  MediaUploadSessionResponse _unwrap(
    Map<String, dynamic>? body, {
    required String emptyMessage,
    required String failureMessage,
  }) {
    if (body == null) {
      throw StateError(emptyMessage);
    }

    final apiResponse = ApiResponse<MediaUploadSessionResponse>.fromJson(
      body,
      (json) =>
          MediaUploadSessionResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? failureMessage);
    }

    return apiResponse.data!;
  }
}
