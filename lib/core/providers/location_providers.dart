import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/geo_location.dart';
import '../services/location_service.dart';

/// Compartido por reports/vets/adoption_centers: los tres necesitan la
/// ubicación actual del dispositivo para ordenar por distancia y para el
/// botón "Cómo llegar".
final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

/// Ubicación actual del dispositivo. `null` si no hay permiso o el usuario
/// lo niega.
final currentLocationProvider = FutureProvider<GeoLocation?>((ref) {
  return ref.watch(locationServiceProvider).getCurrentLocation();
});
