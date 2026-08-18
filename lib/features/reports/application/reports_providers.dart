import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/datasources/reports_remote_datasource.dart';
import '../data/repositories/report_repository_impl.dart';
import '../domain/repositories/report_repository.dart';

// locationServiceProvider/currentLocationProvider viven en core/providers
// (compartidos con vets/adoption_centers); se re-exportan acá para no
// romper los imports existentes de este archivo en el resto de `reports`.
export '../../../core/providers/location_providers.dart';

final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>((ref) {
  return ReportsRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(reportsRemoteDataSourceProvider));
});

final reportByIdProvider = FutureProvider.family((ref, String id) {
  return ref.watch(reportRepositoryProvider).getById(id);
});

/// Historial de reportes de un usuario puntual — lo usa el perfil (propio y
/// ajeno) para la grilla "Mis reportes" (ver ReportsService.findRecent del
/// backend, filtro `reporterId`).
final reportsByReporterProvider = FutureProvider.autoDispose.family((ref, String reporterId) {
  return ref.watch(reportRepositoryProvider).getByReporter(reporterId);
});
