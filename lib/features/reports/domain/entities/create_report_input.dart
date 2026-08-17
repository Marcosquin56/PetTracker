import '../../../../shared/models/geo_location.dart';
import 'enums/health_condition.dart';
import 'enums/pet_species.dart';
import 'enums/report_status.dart';

/// Payload para crear un reporte, previo a subir fotos (que requieren el
/// `id` que el backend asigna al crear).
class CreateReportInput {
  const CreateReportInput({
    required this.species,
    required this.status,
    required this.location,
    this.healthConditions = const [],
    this.petName,
    this.breed,
    this.color,
    this.description,
    this.contactPhone,
  });

  final PetSpecies species;
  final ReportStatus status;
  final GeoLocation location;
  final List<HealthCondition> healthConditions;
  final String? petName;
  final String? breed;
  final String? color;
  final String? description;
  final String? contactPhone;
}
