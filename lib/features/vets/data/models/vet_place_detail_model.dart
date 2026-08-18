import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/vet_place_detail_entity.dart';

class VetPlaceDetailModel extends VetPlaceDetailEntity {
  const VetPlaceDetailModel({
    required super.placeId,
    required super.name,
    required super.location,
    super.address,
    super.phone,
    super.openingHours,
    super.openNow,
  });

  factory VetPlaceDetailModel.fromJson(Map<String, dynamic> json) {
    return VetPlaceDetailModel(
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      phone: json['phone'] as String?,
      openingHours: (json['openingHours'] as List<dynamic>?)?.map((e) => e as String).toList(),
      openNow: json['openNow'] as bool?,
    );
  }
}
