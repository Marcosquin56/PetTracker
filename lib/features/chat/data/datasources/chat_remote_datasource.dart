import 'package:dio/dio.dart';

import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../models/conversation_summary_model.dart';

/// Llamadas HTTP crudas a `/chat/*` del backend propio. El envío/recepción
/// de mensajes en vivo pasa por [ChatSocketService], no por acá.
class ChatRemoteDataSource {
  ChatRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ConversationModel> getOrCreateConversation(String reportId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/conversations',
      data: {'reportId': reportId},
    );
    return ConversationModel.fromJson(response.data!);
  }

  Future<List<ConversationSummaryModel>> getConversations() async {
    final response = await _dio.get<List<dynamic>>('/chat/conversations');
    return response.data!
        .map((e) => ConversationSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessageModel>> getMessages(
    String conversationId, {
    String? before,
    int take = 50,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {if (before != null) 'before': before, 'take': take},
    );
    return response.data!.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
