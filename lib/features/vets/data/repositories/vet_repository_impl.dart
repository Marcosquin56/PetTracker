import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/vet_place_detail_entity.dart';
import '../../domain/entities/vet_place_entity.dart';
import '../../domain/repositories/vet_repository.dart';
import '../datasources/vets_remote_datasource.dart';

class VetRepositoryImpl implements VetRepository {
  VetRepositoryImpl(this._remote);

  final VetsRemoteDataSource _remote;

  @override
  Future<List<VetPlaceEntity>> getNearby({required GeoLocation origin, required double radiusKm}) {
    return _remote.getNearby(lat: origin.latitude, lng: origin.longitude, radiusKm: radiusKm);
  }

  @override
  Future<VetPlaceDetailEntity> getDetail(String placeId) => _remote.getDetail(placeId);
}
