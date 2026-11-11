import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/data/models/auth/api_response.dart';

class AskBackRemoteDataSourceImpl implements AskBackRemoteDataSource {
  AskBackRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<AskBackConversation> start(String voteId) {
    return _conversation(
      dio.post<Map<String, dynamic>>(
        ApiRoutes.askBackConversations,
        data: <String, dynamic>{'voteId': voteId},
      ),
      'Could not start the conversation',
    );
  }

  @override
  Future<AskBackPage<AskBackListItem>> list({String? cursor}) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.askBackConversations,
      queryParameters: _cursorQuery(cursor),
    );
    return _page(
      response.data,
      AskBackListItem.fromJson,
      'Failed to load conversations',
    );
  }

  @override
  Future<AskBackConversation> get(String conversationId) {
    return _conversation(
      dio.get<Map<String, dynamic>>(
        ApiRoutes.askBackConversation(conversationId),
      ),
      'Failed to load the conversation',
    );
  }

  @override
  Future<AskBackPage<AskBackMessage>> messages(
    String conversationId, {
    String? cursor,
    bool newer = false,
  }) async {
    final query = <String, dynamic>{
      ...?_cursorQuery(cursor),
      if (newer) 'direction': 'newer',
    };
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.askBackMessages(conversationId),
      queryParameters: query.isEmpty ? null : query,
    );
    return _page(
      response.data,
      AskBackMessage.fromJson,
      'Failed to load messages',
    );
  }

  @override
  Future<AskBackMessage> send(
    String conversationId, {
    required String clientMessageId,
    required String content,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.askBackMessages(conversationId),
      data: <String, dynamic>{
        'clientMessageId': clientMessageId,
        'content': content,
      },
    );
    final api = ApiResponse<AskBackMessage>.fromJson(
      _body(response.data),
      (json) => AskBackMessage.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (!api.success || api.data == null) {
      throw StateError(api.message ?? 'Could not send the message');
    }
    return api.data!;
  }

  @override
  Future<AskBackReadResult> markRead(
    String conversationId,
    String lastReadMessageId,
  ) async {
    final response = await dio.patch<Map<String, dynamic>>(
      ApiRoutes.askBackRead(conversationId),
      data: <String, dynamic>{'lastReadMessageId': lastReadMessageId},
    );
    final api = ApiResponse<AskBackReadResult>.fromJson(_body(response.data), (
      json,
    ) {
      final map = json is Map ? json : const <String, dynamic>{};
      return AskBackReadResult(
        advanced: map['advanced'] as bool? ?? false,
        unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
      );
    });
    if (!api.success || api.data == null) {
      throw StateError(api.message ?? 'Could not update the read position');
    }
    return api.data!;
  }

  @override
  Future<AskBackConversation> setMuted(String conversationId, bool muted) {
    final path = ApiRoutes.askBackMute(conversationId);
    return _conversation(
      muted
          ? dio.put<Map<String, dynamic>>(path)
          : dio.delete<Map<String, dynamic>>(path),
      'Could not change mute',
    );
  }

  @override
  Future<AskBackConversation> close(String conversationId) {
    return _conversation(
      dio.post<Map<String, dynamic>>(ApiRoutes.askBackClose(conversationId)),
      'Could not close the conversation',
    );
  }

  @override
  Future<AskBackConversation> reopen(String conversationId) {
    return _conversation(
      dio.post<Map<String, dynamic>>(ApiRoutes.askBackReopen(conversationId)),
      'Could not reopen the conversation',
    );
  }

  @override
  Future<AskBackConversation> block(String conversationId, {String? reason}) {
    final trimmed = reason?.trim();
    return _conversation(
      dio.post<Map<String, dynamic>>(
        ApiRoutes.askBackBlock(conversationId),
        data: <String, dynamic>{
          if (trimmed != null && trimmed.isNotEmpty) 'reason': trimmed,
        },
      ),
      'Could not block',
    );
  }

  @override
  Future<AskBackConversation> unblock(String conversationId) {
    return _conversation(
      dio.post<Map<String, dynamic>>(ApiRoutes.askBackUnblock(conversationId)),
      'Could not lift the block',
    );
  }

  Map<String, dynamic>? _cursorQuery(String? cursor) {
    return cursor == null || cursor.isEmpty
        ? null
        : <String, dynamic>{'cursor': cursor};
  }

  Map<String, dynamic> _body(Map<String, dynamic>? body) {
    if (body == null) throw StateError('Empty response');
    return body;
  }

  Future<AskBackConversation> _conversation(
    Future<Response<Map<String, dynamic>>> request,
    String failure,
  ) async {
    final response = await request;
    final api = ApiResponse<AskBackConversation>.fromJson(
      _body(response.data),
      (json) =>
          AskBackConversation.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (!api.success || api.data == null) {
      throw StateError(api.message ?? failure);
    }
    return api.data!;
  }

  AskBackPage<T> _page<T>(
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>) parse,
    String failure,
  ) {
    final api = ApiResponse<List<T>>.fromJson(_body(body), (json) {
      if (json is! List) return <T>[];
      return json
          .whereType<Map>()
          .map((item) => parse(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    });
    if (!api.success || api.data == null) {
      throw StateError(api.message ?? failure);
    }
    final cursor = cursorFromMeta(api.meta);
    return AskBackPage<T>(
      items: api.data!,
      nextCursor: cursor.nextCursor,
      hasMore: cursor.hasMore,
    );
  }
}
