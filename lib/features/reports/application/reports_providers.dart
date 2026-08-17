import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/geo_location.dart';
import '../data/datasources/reports_remote_datasource.dart';
import '../data/repositories/report_repository_impl.dart';
import '../domain/repositories/report_repository.dart';

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

/// Ubicación actual del dispositivo, usada por el feed (ordenar por
/// distancia) y por `ReportCard` (mostrar "X km" en cada tarjeta).
final currentLocationProvider = FutureProvider<GeoLocation?>((ref) {
  return ref.watch(locationServiceProvider).getCurrentLocation();
});

final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>((ref) {
  return ReportsRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(reportsRemoteDataSourceProvider));
});

final reportByIdProvider = FutureProvider.family((ref, String id) {
  return ref.watch(reportRepositoryProvider).getById(id);
});

enum ReportsViewMode { list, map }

/// Toggle lista/mapa de HomeScreen. Vive acá (no en un StatefulWidget) para
/// que sobreviva si HomeScreen se reconstruye por otros providers.
final reportsViewModeProvider = StateProvider<ReportsViewMode>((ref) => ReportsViewMode.list);
