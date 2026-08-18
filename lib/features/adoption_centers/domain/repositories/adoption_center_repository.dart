import '../../../../shared/models/geo_location.dart';
import '../entities/adoption_center_entity.dart';

abstract class AdoptionCenterRepository {
  Future<List<AdoptionCenterEntity>> getAll();

  Future<List<AdoptionCenterEntity>> getNearby({required GeoLocation origin, required double radiusKm});
}
