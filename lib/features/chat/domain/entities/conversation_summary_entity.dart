import 'package:equatable/equatable.dart';

import '../../../reports/domain/entities/enums/pet_species.dart';

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
      ];
}
