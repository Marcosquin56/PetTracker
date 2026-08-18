import 'package:equatable/equatable.dart';

import '../../../../shared/models/geo_location.dart';
import 'enums/health_condition.dart';
import 'enums/pet_species.dart';
import 'enums/report_status.dart';

/// Representación de dominio de un reporte de mascota, sin dependencias de
/// Firebase. La (de)serialización específica de Firestore vive en
/// [PetReportModel] (`data/models`), que extiende esta clase.
class PetReportEntity extends Equatable {
  const PetReportEntity({
    required this.id,
    required this.reporterId,
    required this.species,
    required this.status,
    required this.location,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
    this.healthConditions = const [],
    this.petName,
    this.breed,
    this.color,
    this.description,
    this.contactPhone,
    this.isResolved = false,
    this.reporterName,
    this.reporterPhotoUrl,
  });

  /// ID del documento en Firestore.
  final String id;

  /// UID del usuario (Firebase Auth) que creó el reporte.
  final String reporterId;

  /// Nombre/foto del reportero, para el link "Reportado por" del detalle y
  /// para poder navegar a `/profile/:reporterId`.
  final String? reporterName;
  final String? reporterPhotoUrl;

  final PetSpecies species;
  final ReportStatus status;
  final List<HealthCondition> healthConditions;

  /// URLs públicas en Firebase Storage. La primera se usa como foto principal.
  final List<String> photoUrls;

  final GeoLocation location;

  /// Nombre de la mascota, relevante sobre todo cuando [status] es [ReportStatus.lost].
  final String? petName;
  final String? breed;
  final String? color;
  final String? description;

  /// Teléfono / contacto visible en el detalle del reporte.
  final String? contactPhone;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// true cuando el animal ya fue reunido con su dueño o quedó a salvo.
  final bool isResolved;

  String get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';

  /// Distancia en kilómetros desde [origin] (p. ej. la ubicación actual del usuario).
  double distanceFromKm(GeoLocation origin) => location.distanceInKmTo(origin);

  PetReportEntity copyWith({
    String? id,
    String? reporterId,
    PetSpecies? species,
    ReportStatus? status,
    List<HealthCondition>? healthConditions,
    List<String>? photoUrls,
    GeoLocation? location,
    String? petName,
    String? breed,
    String? color,
    String? description,
    String? contactPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isResolved,
  }) {
    return PetReportEntity(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      species: species ?? this.species,
      status: status ?? this.status,
      healthConditions: healthConditions ?? this.healthConditions,
      photoUrls: photoUrls ?? this.photoUrls,
      location: location ?? this.location,
      petName: petName ?? this.petName,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      description: description ?? this.description,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isResolved: isResolved ?? this.isResolved,
      reporterName: reporterName,
      reporterPhotoUrl: reporterPhotoUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reporterId,
        species,
        status,
        healthConditions,
        photoUrls,
        location,
        petName,
        breed,
        color,
        description,
        contactPhone,
        createdAt,
        updatedAt,
        isResolved,
        reporterName,
        reporterPhotoUrl,
      ];
}
