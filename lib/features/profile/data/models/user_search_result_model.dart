import '../../domain/entities/user_search_result_entity.dart';

class UserSearchResultModel extends UserSearchResultEntity {
  const UserSearchResultModel({required super.id, super.displayName, super.photoUrl});

  factory UserSearchResultModel.fromJson(Map<String, dynamic> json) {
    return UserSearchResultModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
