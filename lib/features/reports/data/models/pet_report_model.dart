import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/enums/health_condition.dart';
import '../../domain/entities/enums/pet_species.dart';
import '../../domain/entities/enums/report_status.dart';
import '../../domain/entities/pet_report_entity.dart';

/// DTO responsable de convertir entre [PetReportEntity] y el JSON del
/// endpoint `/reports` del backend propio.
class PetReportModel extends PetReportEntity {
  const PetReportModel({
    required super.id,
    required super.reporterId,
    required super.species,
    required super.status,
    required super.location,
    required super.photoUrls,
    required super.createdAt,
    required super.updatedAt,
    super.healthConditions,
    super.petName,
    super.breed,
    super.color,
    super.description,
    super.contactPhone,
    super.isResolved,
  });

  factory PetReportModel.fromEntity(PetReportEntity entity) {
    return PetReportModel(
      id: entity.id,
      reporterId: entity.reporterId,
      species: entity.species,
      status: entity.status,
      healthConditions: entity.healthConditions,
      photoUrls: entity.photoUrls,
      location: entity.location,
      petName: entity.petName,
      breed: entity.breed,
      color: entity.color,
      description: entity.description,
      contactPhone: entity.contactPhone,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isResolved: entity.isResolved,
    );
  }

  factory PetReportModel.fromJson(Map<String, dynamic> json) {
    return PetReportModel(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      species: PetSpecies.fromApiValue(json['species'] as String),
      status: ReportStatus.fromApiValue(json['status'] as String),
      healthConditions: ((json['healthConditions'] as List<dynamic>?) ?? const [])
          .map((value) => HealthCondition.fromApiValue(value as String))
          .toList(),
      photoUrls: List<String>.from((json['photoUrls'] as List<dynamic>?) ?? const []),
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      petName: json['petName'] as String?,
      breed: json['breed'] as String?,
      color: json['color'] as String?,
      description: json['description'] as String?,
      contactPhone: json['contactPhone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      isResolved: json['isResolved'] as bool? ?? false,
    );
  }

  /// Payload para `POST/PATCH /reports`. No incluye `id`/`createdAt`/
  /// `updatedAt`, que los asigna el backend.
  Map<String, dynamic> toJson() {
    return {
      'reporterId': reporterId,
      'species': species.apiValue,
      'status': status.apiValue,
      'healthConditions': healthConditions.map((c) => c.apiValue).toList(),
      'photoUrls': photoUrls,
      'location': location.toJson(),
      if (petName != null) 'petName': petName,
      if (breed != null) 'breed': breed,
      if (color != null) 'color': color,
      if (description != null) 'description': description,
      if (contactPhone != null) 'contactPhone': contactPhone,
      'isResolved': isResolved,
    };
  }
}
