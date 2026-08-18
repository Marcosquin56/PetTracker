import '../entities/user_profile_summary_entity.dart';
import '../entities/user_rating_entity.dart';
import '../entities/user_search_result_entity.dart';

abstract class ProfileRepository {
  Future<UserProfileSummaryEntity> getProfile(String userId);

  Future<List<UserSearchResultEntity>> search(String query);

  Future<List<UserRatingEntity>> getRatings(String userId);

  Future<void> rateUser(String userId, {required int score, String? comment});
}
