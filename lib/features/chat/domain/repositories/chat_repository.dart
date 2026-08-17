import '../entities/chat_message_entity.dart';
import '../entities/conversation_entity.dart';
import '../entities/conversation_summary_entity.dart';

abstract class ChatRepository {
  Future<ConversationEntity> getOrCreateConversation(String reportId);

  /// Más recientes primero; paginar pasando `before` (createdAt del último
  /// mensaje ya visto).
  Future<List<ChatMessageEntity>> getMessages(String conversationId, {String? before, int take = 50});

  /// Conversaciones del usuario, más actividad reciente primero.
  Future<List<ConversationSummaryEntity>> getConversations();
}
