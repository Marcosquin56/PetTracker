import 'package:equatable/equatable.dart';

/// Perfil público de un usuario (`GET /users/:id`): lo que puede ver
/// cualquiera, propio o ajeno — nunca incluye email ni datos privados (eso
/// vive en `UserProfileEntity`, ver features/auth). La (de)serialización
/// específica del backend vive en `UserProfileSummaryModel` (`data/models`).
class UserProfileSummaryEntity extends Equatable {
  const UserProfileSummaryEntity({
    required this.id,
    required this.createdAt,
    required this.reportsCount,
    required this.ratingCount,
    this.displayName,
    this.photoUrl,
    this.ratingAverage,
  });

  final String id;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;

  /// Cantidad de reportes que hizo (avistamientos/rescates) — "registro de
  /// los animales que encontró".
  final int reportsCount;

  /// `null` si todavía no tiene calificaciones.
  final double? ratingAverage;
  final int ratingCount;

  @override
  List<Object?> get props => [id, displayName, photoUrl, createdAt, reportsCount, ratingAverage, ratingCount];
}
