import 'package:dio/dio.dart';

import '../models/adoption_center_model.dart';

/// Llamadas HTTP crudas a `/adoption-centers*` del backend propio.
class AdoptionCentersRemoteDataSource {
  AdoptionCentersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AdoptionCenterModel>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/adoption-centers');
    return _toModelList(response.data!);
  }

  Future<List<AdoptionCenterModel>> getNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/adoption-centers/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm},
    );
    return _toModelList(response.data!);
  }

  List<AdoptionCenterModel> _toModelList(List<dynamic> raw) {
    return raw.map((e) => AdoptionCenterModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
