import 'package:equatable/equatable.dart';

import '../../../reports/domain/entities/enums/pet_species.dart';
import 'chat_message_entity.dart';

/// Una fila del inbox de chats: la conversación + el otro participante +
/// el último mensaje, ya resueltos por el backend (GET /chat/conversations)
/// para no tener que pedir cada conversación por separado desde el cliente.
class ConversationSummaryEntity extends Equatable {
  const ConversationSummaryEntity({
    required this.id,
    required this.otherUserId,
    required this.otherUserDisplayName,
    required this.otherUserPhotoUrl,
    required this.reportId,
    required this.petName,
    required this.species,
    required this.lastMessageContent,
    required this.lastMessageAt,
    required this.updatedAt,
    this.lastMessageType,
    this.unreadCount = 0,
  });

  final String id;
  final String otherUserId;
  final String? otherUserDisplayName;
  final String? otherUserPhotoUrl;
  final String? reportId;
  final String? petName;
  final PetSpecies? species;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final DateTime updatedAt;
  final ChatMessageType? lastMessageType;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  /// Texto para la fila del inbox: el contenido tal cual si es texto (o el
  /// caption de un adjunto, si le pusieron uno), o una etiqueta genérica
  /// según el tipo cuando no hay texto que mostrar (p. ej. una foto sin pie).
  String get lastMessagePreview {
    if (lastMessageContent != null && lastMessageContent!.isNotEmpty) return lastMessageContent!;
    switch (lastMessageType) {
      case ChatMessageType.image:
        return '📷 Foto';
      case ChatMessageType.audio:
        return '🎤 Mensaje de voz';
      case ChatMessageType.file:
        return '📎 Archivo';
      case ChatMessageType.text:
      case null:
        return '';
    }
  }

  @override
  List<Object?> get props => [
        id,
        otherUserId,
        otherUserDisplayName,
        otherUserPhotoUrl,
        reportId,
        petName,
        species,
        lastMessageContent,
        lastMessageAt,
        updatedAt,
        lastMessageType,
        unreadCount,
      ];
}
