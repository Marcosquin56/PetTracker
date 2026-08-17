import '../domain/entities/enums/pet_species.dart';
import '../domain/entities/enums/report_status.dart';

class ReportFilters {
  const ReportFilters({this.species, this.status, this.radiusKm = 10});

  final PetSpecies? species;
  final ReportStatus? status;
  final double radiusKm;

  ReportFilters copyWith({
    PetSpecies? species,
    bool clearSpecies = false,
    ReportStatus? status,
    bool clearStatus = false,
    double? radiusKm,
  }) {
    return ReportFilters(
      species: clearSpecies ? null : (species ?? this.species),
      status: clearStatus ? null : (status ?? this.status),
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }
}
