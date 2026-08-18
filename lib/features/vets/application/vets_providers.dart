import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/providers/location_providers.dart';
import '../data/datasources/vets_remote_datasource.dart';
import '../data/repositories/vet_repository_impl.dart';
import '../domain/entities/vet_place_detail_entity.dart';
import '../domain/entities/vet_place_entity.dart';
import '../domain/repositories/vet_repository.dart';

/// Radio de búsqueda fijo: veterinarias son un servicio de cercanía, a
/// diferencia del feed de reportes no tiene sentido dejarlo configurable acá.
const vetsSearchRadiusKm = 5.0;

final vetsRemoteDataSourceProvider = Provider<VetsRemoteDataSource>((ref) {
  return VetsRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final vetRepositoryProvider = Provider<VetRepository>((ref) {
  return VetRepositoryImpl(ref.watch(vetsRemoteDataSourceProvider));
});

/// Lanza [LocationUnavailableException] si no hay ubicación (permiso
/// denegado o servicio apagado) — la UI lo distingue de un error de red.
final nearbyVetsProvider = FutureProvider.autoDispose<List<VetPlaceEntity>>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  if (location == null) throw LocationUnavailableException();

  return ref.watch(vetRepositoryProvider).getNearby(origin: location, radiusKm: vetsSearchRadiusKm);
});

final vetDetailProvider = FutureProvider.autoDispose.family<VetPlaceDetailEntity, String>((ref, placeId) {
  return ref.watch(vetRepositoryProvider).getDetail(placeId);
});

class LocationUnavailableException implements Exception {}
