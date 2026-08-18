import '../../domain/entities/user_rating_entity.dart';

class UserRatingModel extends UserRatingEntity {
  const UserRatingModel({
    required super.id,
    required super.score,
    required super.createdAt,
    required super.raterId,
    super.comment,
    super.raterName,
    super.raterPhotoUrl,
  });

  factory UserRatingModel.fromJson(Map<String, dynamic> json) {
    final rater = json['rater'] as Map<String, dynamic>;
    return UserRatingModel(
      id: json['id'] as String,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      raterId: rater['id'] as String,
      raterName: rater['displayName'] as String?,
      raterPhotoUrl: rater['photoUrl'] as String?,
    );
  }
}
