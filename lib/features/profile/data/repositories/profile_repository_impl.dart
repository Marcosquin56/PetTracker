import '../../domain/entities/user_profile_summary_entity.dart';
import '../../domain/entities/user_rating_entity.dart';
import '../../domain/entities/user_search_result_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<UserProfileSummaryEntity> getProfile(String userId) => _remote.getProfile(userId);

  @override
  Future<List<UserSearchResultEntity>> search(String query) => _remote.search(query);

  @override
  Future<List<UserRatingEntity>> getRatings(String userId) => _remote.getRatings(userId);

  @override
  Future<void> rateUser(String userId, {required int score, String? comment}) {
    return _remote.rateUser(userId, score: score, comment: comment);
  }
}
