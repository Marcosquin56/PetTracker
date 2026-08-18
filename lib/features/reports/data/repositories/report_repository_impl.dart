import 'package:image_picker/image_picker.dart';

import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/create_report_input.dart';
import '../../domain/entities/pet_report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._remote);

  final ReportsRemoteDataSource _remote;

  @override
  Future<List<PetReportEntity>> getRecent() => _remote.getRecent();

  @override
  Future<List<PetReportEntity>> getNearby({required GeoLocation origin, required double radiusKm}) {
    return _remote.getNearby(lat: origin.latitude, lng: origin.longitude, radiusKm: radiusKm);
  }

  @override
  Future<PetReportEntity> getById(String id) => _remote.getById(id);

  @override
  Future<List<PetReportEntity>> getByReporter(String reporterId) => _remote.getRecent(reporterId: reporterId);

  @override
  Future<PetReportEntity> create(CreateReportInput input) => _remote.create(input);

  @override
  Future<PetReportEntity> addPhoto(String reportId, XFile photo) => _remote.addPhoto(reportId, photo);

  @override
  Future<PetReportEntity> markResolved(String id, bool isResolved) =>
      _remote.updateResolved(id, isResolved);
}
