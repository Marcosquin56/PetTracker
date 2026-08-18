import 'package:equatable/equatable.dart';

class UserRatingEntity extends Equatable {
  const UserRatingEntity({
    required this.id,
    required this.score,
    required this.createdAt,
    required this.raterId,
    this.comment,
    this.raterName,
    this.raterPhotoUrl,
  });

  final String id;
  final int score;
  final String? comment;
  final DateTime createdAt;
  final String raterId;
  final String? raterName;
  final String? raterPhotoUrl;

  @override
  List<Object?> get props => [id, score, comment, createdAt, raterId, raterName, raterPhotoUrl];
}
