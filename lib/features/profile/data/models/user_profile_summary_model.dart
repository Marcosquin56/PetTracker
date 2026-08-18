import '../../domain/entities/user_profile_summary_entity.dart';

class UserProfileSummaryModel extends UserProfileSummaryEntity {
  const UserProfileSummaryModel({
    required super.id,
    required super.createdAt,
    required super.reportsCount,
    required super.ratingCount,
    super.displayName,
    super.photoUrl,
    super.ratingAverage,
  });

  factory UserProfileSummaryModel.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as Map<String, dynamic>;
    return UserProfileSummaryModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      reportsCount: json['reportsCount'] as int,
      ratingAverage: (rating['average'] as num?)?.toDouble(),
      ratingCount: rating['count'] as int,
    );
  }
}
