import '../../../reports/domain/entities/enums/pet_species.dart';
import '../../domain/entities/conversation_summary_entity.dart';
import 'chat_message_model.dart';

class ConversationSummaryModel extends ConversationSummaryEntity {
  const ConversationSummaryModel({
    required super.id,
    required super.otherUserId,
    required super.otherUserDisplayName,
    required super.otherUserPhotoUrl,
    required super.reportId,
    required super.petName,
    required super.species,
    required super.lastMessageContent,
    required super.lastMessageAt,
    required super.updatedAt,
    super.lastMessageType,
    super.unreadCount,
  });

  factory ConversationSummaryModel.fromJson(Map<String, dynamic> json) {
    final otherUser = json['otherUser'] as Map<String, dynamic>;
    final report = json['report'] as Map<String, dynamic>?;
    final lastMessage = json['lastMessage'] as Map<String, dynamic>?;

    return ConversationSummaryModel(
      id: json['id'] as String,
      otherUserId: otherUser['id'] as String,
      otherUserDisplayName: otherUser['displayName'] as String?,
      otherUserPhotoUrl: otherUser['photoUrl'] as String?,
      reportId: report?['id'] as String?,
      petName: report?['petName'] as String?,
      species: report == null ? null : PetSpecies.fromApiValue(report['species'] as String),
      lastMessageContent: lastMessage?['content'] as String?,
      lastMessageAt:
          lastMessage == null ? null : DateTime.parse(lastMessage['createdAt'] as String).toUtc(),
      lastMessageType: lastMessage == null ? null : ChatMessageModel.fromJson(lastMessage).type,
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
