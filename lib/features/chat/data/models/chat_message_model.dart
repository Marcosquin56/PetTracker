import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.content,
    required super.createdAt,
    super.type,
    super.attachmentUrl,
    super.attachmentName,
    super.attachmentMimeType,
    super.attachmentDurationMs,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      type: _typeFromApiValue(json['type'] as String?),
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentName: json['attachmentName'] as String?,
      attachmentMimeType: json['attachmentMimeType'] as String?,
      attachmentDurationMs: json['attachmentDurationMs'] as int?,
    );
  }

  static ChatMessageType _typeFromApiValue(String? value) {
    return ChatMessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ChatMessageType.text,
    );
  }
}
