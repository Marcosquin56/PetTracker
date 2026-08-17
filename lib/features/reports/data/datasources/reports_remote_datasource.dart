import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/create_report_input.dart';
import '../models/pet_report_model.dart';

/// Llamadas HTTP crudas a `/reports*` del backend propio.
class ReportsRemoteDataSource {
  ReportsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PetReportModel>> getRecent() async {
    final response = await _dio.get<List<dynamic>>('/reports');
    return _toModelList(response.data!);
  }

  Future<List<PetReportModel>> getNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/reports/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm},
    );
    return _toModelList(response.data!);
  }

  Future<PetReportModel> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/reports/$id');
    return PetReportModel.fromJson(response.data!);
  }

  Future<PetReportModel> create(CreateReportInput input) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/reports',
      data: {
        'species': input.species.apiValue,
        'status': input.status.apiValue,
        'healthConditions': input.healthConditions.map((c) => c.apiValue).toList(),
        'location': input.location.toJson(),
        if (input.petName != null) 'petName': input.petName,
        if (input.breed != null) 'breed': input.breed,
        if (input.color != null) 'color': input.color,
        if (input.description != null) 'description': input.description,
        if (input.contactPhone != null) 'contactPhone': input.contactPhone,
      },
    );
    return PetReportModel.fromJson(response.data!);
  }

  Future<PetReportModel> addPhoto(String reportId, XFile photo) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(photo.path, filename: photo.name),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/reports/$reportId/photos',
      data: formData,
    );
    return PetReportModel.fromJson(response.data!);
  }

  Future<PetReportModel> updateResolved(String id, bool isResolved) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/reports/$id',
      data: {'isResolved': isResolved},
    );
    return PetReportModel.fromJson(response.data!);
  }

  List<PetReportModel> _toModelList(List<dynamic> raw) {
    return raw.map((e) => PetReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
