import 'package:equatable/equatable.dart';

import '../../../../shared/models/geo_location.dart';

/// Casa de adopción — lista curada a mano por el equipo de PetTracker (ver
/// backend/prisma/seed.ts), no hay CRUD de usuario. [location]/[mapsUrl] son
/// opcionales porque no todas las casas tienen coordenadas cargadas todavía.
class AdoptionCenterEntity extends Equatable {
  const AdoptionCenterEntity({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.whatsapp,
    this.email,
    this.description,
    this.photoUrl,
    this.mapsUrl,
    this.location,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? description;
  final String? photoUrl;
  final String? mapsUrl;
  final GeoLocation? location;

  /// Solo viene poblado cuando la casa salió de `/adoption-centers/nearby`.
  final double? distanceKm;

  bool get hasContact => phone != null || whatsapp != null || email != null;

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        whatsapp,
        email,
        description,
        photoUrl,
        mapsUrl,
        location,
        distanceKm,
      ];
}
