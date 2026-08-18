import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/adoption_center_entity.dart';

class AdoptionCenterModel extends AdoptionCenterEntity {
  const AdoptionCenterModel({
    required super.id,
    required super.name,
    super.address,
    super.phone,
    super.whatsapp,
    super.email,
    super.description,
    super.photoUrl,
    super.mapsUrl,
    super.location,
    super.distanceKm,
  });

  /// El backend expone `latitude`/`longitude` sueltos (no anidados en
  /// `location` como en `/reports`, ver AdoptionCentersService), y ambos son
  /// nullable porque no todas las casas tienen coordenadas cargadas.
  factory AdoptionCenterModel.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();

    return AdoptionCenterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      photoUrl: json['photoUrl'] as String?,
      mapsUrl: json['mapsUrl'] as String?,
      location: latitude != null && longitude != null
          ? GeoLocation(latitude: latitude, longitude: longitude)
          : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}
