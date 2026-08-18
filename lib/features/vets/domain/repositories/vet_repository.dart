import '../../../../shared/models/geo_location.dart';
import '../entities/vet_place_detail_entity.dart';
import '../entities/vet_place_entity.dart';

abstract class VetRepository {
  Future<List<VetPlaceEntity>> getNearby({required GeoLocation origin, required double radiusKm});

  Future<VetPlaceDetailEntity> getDetail(String placeId);
}
