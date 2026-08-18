import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/adoption_center_entity.dart';
import '../../domain/repositories/adoption_center_repository.dart';
import '../datasources/adoption_centers_remote_datasource.dart';

class AdoptionCenterRepositoryImpl implements AdoptionCenterRepository {
  AdoptionCenterRepositoryImpl(this._remote);

  final AdoptionCentersRemoteDataSource _remote;

  @override
  Future<List<AdoptionCenterEntity>> getAll() => _remote.getAll();

  @override
  Future<List<AdoptionCenterEntity>> getNearby({required GeoLocation origin, required double radiusKm}) {
    return _remote.getNearby(lat: origin.latitude, lng: origin.longitude, radiusKm: radiusKm);
  }
}
