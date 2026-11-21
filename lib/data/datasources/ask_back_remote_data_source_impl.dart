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
  Future<AskBackAccess> getAccess(String voteId) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.askBackAccess,
      queryParameters: <String, dynamic>{'voteId': voteId},
    );
    return _access(response.data, 'Could not check Ask Back access');
  }

  @override
  Future<AskBackAccess> getCardAccess(
    String contentType,
    String contentId,
  ) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.askBackCardAccess,
      queryParameters: <String, dynamic>{
        'contentType': contentType,
        'contentId': contentId,
      },
    );
    return _access(response.data, 'Could not check your plan');
  }

  @override
  Future<AskBackAccess> unlock(String voteId) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.askBackUnlocks,
      data: <String, dynamic>{'voteId': voteId},
    );
    return _access(response.data, 'Could not unlock this card');
  }

  @override
  Future<AskBackBlocksPage> listBlocks({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.askBackBlocks,
      queryParameters: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      },
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty blocked people response');
    }
    final api = ApiResponse<List<AskBackBlockItem>>.fromJson(body, (json) {
      if (json is! List) return const <AskBackBlockItem>[];
      return [
        for (final item in json)
          if (item is Map)
            AskBackBlockItem.fromJson(Map<String, dynamic>.from(item)),
      ];
    });
    if (!api.success || api.data == null) {
      throw StateError(api.message ?? 'Could not load blocked people');
    }
    return AskBackBlocksPage.fromApi(items: api.data!, meta: api.meta);
  }

  @override
  Future<void> unblockByBlockId(String blockId) async {
    final response = await dio.delete<Map<String, dynamic>>(
      ApiRoutes.askBackBlockById(blockId),
    );
    final api = ApiResponse<Object?>.fromJson(
      _body(response.data),
      (_) => null,
    );
    if (!api.success) {
      throw StateError(api.message ?? 'Could not unblock');
    }
  }

  AskBackAccess _access(Map<String, dynamic>? body, String failure) {
    final api = ApiResponse<AskBackAccess>.fromJson(
      _body(body),
      (json) => AskBackAccess.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (!api.success || api.data == null) {
      throw StateError(api.message ?? failure);
    }
    return api.data!;
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
