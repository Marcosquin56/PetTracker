import 'package:dio/dio.dart';

import '../models/user_profile_summary_model.dart';
import '../models/user_rating_model.dart';
import '../models/user_search_result_model.dart';

/// Llamadas HTTP crudas a `/users/:id`, `/users/search` y `/users/:id/ratings`.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserProfileSummaryModel> getProfile(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>('/users/$userId');
    return UserProfileSummaryModel.fromJson(response.data!);
  }

  Future<List<UserSearchResultModel>> search(String query) async {
    final response = await _dio.get<List<dynamic>>('/users/search', queryParameters: {'q': query});
    return response.data!.map((e) => UserSearchResultModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserRatingModel>> getRatings(String userId) async {
    final response = await _dio.get<List<dynamic>>('/users/$userId/ratings');
    return response.data!.map((e) => UserRatingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> rateUser(String userId, {required int score, String? comment}) {
    return _dio.post<void>(
      '/users/$userId/ratings',
      data: {'score': score, if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
  }
}
