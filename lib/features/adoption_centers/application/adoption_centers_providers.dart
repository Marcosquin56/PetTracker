import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/providers/location_providers.dart';
import '../data/datasources/adoption_centers_remote_datasource.dart';
import '../data/repositories/adoption_center_repository_impl.dart';
import '../domain/entities/adoption_center_entity.dart';
import '../domain/repositories/adoption_center_repository.dart';

final adoptionCentersRemoteDataSourceProvider = Provider<AdoptionCentersRemoteDataSource>((ref) {
  return AdoptionCentersRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final adoptionCenterRepositoryProvider = Provider<AdoptionCenterRepository>((ref) {
  return AdoptionCenterRepositoryImpl(ref.watch(adoptionCentersRemoteDataSourceProvider));
});

/// Siempre trae *todas* las casas de adopción (a diferencia de vets, acá no
/// tiene sentido filtrar por radio: son pocas y curadas a mano, y varias
/// todavía no tienen coordenadas cargadas — ver AdoptionCenterModel). Cuando
/// hay ubicación disponible, se ordenan por distancia dejando al final las
/// que no tienen ubicación cargada.
final adoptionCentersProvider = FutureProvider.autoDispose<List<AdoptionCenterEntity>>((ref) async {
  final repository = ref.watch(adoptionCenterRepositoryProvider);
  final location = await ref.watch(currentLocationProvider.future);
  final centers = await repository.getAll();

  if (location == null) return centers;

  final withDistance = centers
      .map(
        (center) => center.location == null
            ? center
            : _withDistance(center, center.location!.distanceInKmTo(location)),
      )
      .toList();

  withDistance.sort((a, b) {
    if (a.distanceKm == null && b.distanceKm == null) return 0;
    if (a.distanceKm == null) return 1;
    if (b.distanceKm == null) return -1;
    return a.distanceKm!.compareTo(b.distanceKm!);
  });

  return withDistance;
});

AdoptionCenterEntity _withDistance(AdoptionCenterEntity center, double distanceKm) {
  return AdoptionCenterEntity(
    id: center.id,
    name: center.name,
    address: center.address,
    phone: center.phone,
    whatsapp: center.whatsapp,
    email: center.email,
    description: center.description,
    photoUrl: center.photoUrl,
    mapsUrl: center.mapsUrl,
    location: center.location,
    distanceKm: distanceKm,
  );
}
