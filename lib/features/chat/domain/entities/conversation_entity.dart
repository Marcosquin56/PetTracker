import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.reportId,
    required this.userAId,
    required this.userBId,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String userAId;
  final String userBId;
  final DateTime createdAt;

  /// El otro participante, dado tu propio uid.
  String otherUserId(String currentUserId) => userAId == currentUserId ? userBId : userAId;

  @override
  List<Object?> get props => [id, reportId, userAId, userBId, createdAt];
}
