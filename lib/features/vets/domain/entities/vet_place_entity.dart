import 'package:equatable/equatable.dart';

import '../../../../shared/models/geo_location.dart';

/// Veterinaria devuelta por `/vets/nearby` (proxy del backend a Google
/// Places). `distanceKm` la calcula el backend con Haversine porque Nearby
/// Search no la devuelve.
class VetPlaceEntity extends Equatable {
  const VetPlaceEntity({
    required this.placeId,
    required this.name,
    required this.location,
    required this.distanceKm,
    this.address,
    this.rating,
    this.userRatingsTotal,
    this.openNow,
  });

  final String placeId;
  final String name;
  final String? address;
  final GeoLocation location;
  final double distanceKm;
  final double? rating;
  final int? userRatingsTotal;
  final bool? openNow;

  @override
  List<Object?> get props => [placeId, name, address, location, distanceKm, rating, userRatingsTotal, openNow];
}
