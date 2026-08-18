import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/vet_place_entity.dart';

class VetPlaceModel extends VetPlaceEntity {
  const VetPlaceModel({
    required super.placeId,
    required super.name,
    required super.location,
    required super.distanceKm,
    super.address,
    super.rating,
    super.userRatingsTotal,
    super.openNow,
  });

  factory VetPlaceModel.fromJson(Map<String, dynamic> json) {
    return VetPlaceModel(
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['userRatingsTotal'] as int?,
      openNow: json['openNow'] as bool?,
    );
  }
}
