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

  /// Marca la conversación como leída hasta ahora (limpia su no-leídos).
  Future<void> markAsRead(String conversationId);

  /// Sube un adjunto y crea el mensaje. `type` es "image", "audio" o "file";
  /// `durationMs` solo aplica a "audio".
  Future<ChatMessageEntity> uploadAttachment(
    String conversationId, {
    required String filePath,
    required String fileName,
    required String type,
    String? caption,
    int? durationMs,
  });
}
