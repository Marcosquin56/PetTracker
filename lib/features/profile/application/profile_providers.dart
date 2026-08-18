import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/datasources/profile_remote_datasource.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/entities/user_profile_summary_entity.dart';
import '../domain/entities/user_rating_entity.dart';
import '../domain/entities/user_search_result_entity.dart';
import '../domain/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

final userProfileProvider =
    FutureProvider.autoDispose.family<UserProfileSummaryEntity, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).getProfile(userId);
});

final userRatingsProvider = FutureProvider.autoDispose.family<List<UserRatingEntity>, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).getRatings(userId);
});

/// `null`/vacío no dispara búsqueda — ver `SearchScreen`, que solo llama a
/// `ref.refresh` cuando el usuario ya escribió algo.
final userSearchResultsProvider =
    FutureProvider.autoDispose.family<List<UserSearchResultEntity>, String>((ref, query) {
  if (query.trim().length < 2) return Future.value(const []);
  return ref.watch(profileRepositoryProvider).search(query.trim());
});
