import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/conversation_summary_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;

  @override
  Future<ConversationEntity> getOrCreateConversation(String reportId) =>
      _remote.getOrCreateConversation(reportId);

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId, {String? before, int take = 50}) =>
      _remote.getMessages(conversationId, before: before, take: take);

  @override
  Future<List<ConversationSummaryEntity>> getConversations() => _remote.getConversations();

  @override
  Future<void> markAsRead(String conversationId) => _remote.markAsRead(conversationId);

  @override
  Future<ChatMessageEntity> uploadAttachment(
    String conversationId, {
    required String filePath,
    required String fileName,
    required String type,
    String? caption,
    int? durationMs,
  }) =>
      _remote.uploadAttachment(
        conversationId,
        filePath: filePath,
        fileName: fileName,
        type: type,
        caption: caption,
        durationMs: durationMs,
      );
}
