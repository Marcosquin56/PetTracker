import 'package:dio/dio.dart';

import '../models/vet_place_detail_model.dart';
import '../models/vet_place_model.dart';

/// Llamadas HTTP crudas a `/vets*` del backend propio (que a su vez proxya
/// Google Places — ver backend/src/vets/vets.service.ts).
class VetsRemoteDataSource {
  VetsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<VetPlaceModel>> getNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/vets/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm},
    );
    return response.data!.map((e) => VetPlaceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VetPlaceDetailModel> getDetail(String placeId) async {
    final response = await _dio.get<Map<String, dynamic>>('/vets/$placeId');
    return VetPlaceDetailModel.fromJson(response.data!);
  }
}
