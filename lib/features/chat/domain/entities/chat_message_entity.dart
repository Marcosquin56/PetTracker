import 'package:equatable/equatable.dart';

enum ChatMessageType { text, image, audio, file }

class ChatMessageEntity extends Equatable {
  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.type = ChatMessageType.text,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMimeType,
    this.attachmentDurationMs,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final ChatMessageType type;

  /// Solo si `type != text`.
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMimeType;
  final int? attachmentDurationMs;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        createdAt,
        type,
        attachmentUrl,
        attachmentName,
        attachmentMimeType,
        attachmentDurationMs,
      ];
}
