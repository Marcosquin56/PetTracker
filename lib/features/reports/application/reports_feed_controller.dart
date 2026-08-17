import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/pet_report_entity.dart';
import 'report_filters.dart';
import 'reports_providers.dart';

final reportFiltersProvider = StateProvider<ReportFilters>((ref) => const ReportFilters());

final reportsFeedControllerProvider =
    AsyncNotifierProvider<ReportsFeedController, List<PetReportEntity>>(ReportsFeedController.new);

/// Carga el feed usando `/reports/nearby` si hay permiso de ubicación, o
/// `/reports` (feed reciente sin distancia) si no. La especie/estado se
/// filtran del lado del cliente porque el backend solo filtra por radio.
class ReportsFeedController extends AsyncNotifier<List<PetReportEntity>> {
  @override
  Future<List<PetReportEntity>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<PetReportEntity>> _load() async {
    final filters = ref.watch(reportFiltersProvider);
    final repository = ref.read(reportRepositoryProvider);
    final location = await ref.read(locationServiceProvider).getCurrentLocation();

    final reports = location != null
        ? await repository.getNearby(origin: location, radiusKm: filters.radiusKm)
        : await repository.getRecent();

    return reports.where((report) {
      if (filters.species != null && report.species != filters.species) return false;
      if (filters.status != null && report.status != filters.status) return false;
      return true;
    }).toList();
  }
}
