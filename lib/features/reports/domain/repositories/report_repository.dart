import 'package:image_picker/image_picker.dart';

import '../../../../shared/models/geo_location.dart';
import '../entities/create_report_input.dart';
import '../entities/pet_report_entity.dart';

abstract class ReportRepository {
  /// Feed general, sin filtro de ubicación.
  Future<List<PetReportEntity>> getRecent();

  /// Reportes dentro de `radiusKm` de `origin`, ordenados por distancia.
  Future<List<PetReportEntity>> getNearby({required GeoLocation origin, required double radiusKm});

  Future<PetReportEntity> getById(String id);

  /// Todos los reportes hechos por `reporterId` (incluye resueltos) — para
  /// la grilla "Mis reportes" del perfil.
  Future<List<PetReportEntity>> getByReporter(String reporterId);

  Future<PetReportEntity> create(CreateReportInput input);

  Future<PetReportEntity> addPhoto(String reportId, XFile photo);

  Future<PetReportEntity> markResolved(String id, bool isResolved);
}
