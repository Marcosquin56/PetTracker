import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Coordenada geográfica con dirección legible opcional.
///
/// Value object puro (sin dependencias de red ni de plataforma) que viaja
/// como JSON plano `{latitude, longitude, address}` entre la API REST del
/// backend propio y el resto de la app.
class GeoLocation extends Equatable {
  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  })  : assert(latitude >= -90 && latitude <= 90, 'Latitud fuera de rango'),
        assert(
          longitude >= -180 && longitude <= 180,
          'Longitud fuera de rango',
        );

  final double latitude;
  final double longitude;
  final String? address;

  static const _earthRadiusKm = 6371.0;

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
    };
  }

  /// Distancia en kilómetros usando la fórmula de Haversine.
  /// No depende de `geolocator` para que el modelo siga siendo Dart puro y
  /// testeable sin plugins de plataforma.
  double distanceInKmTo(GeoLocation other) {
    final dLat = _degToRad(other.latitude - latitude);
    final dLng = _degToRad(other.longitude - longitude);

    final lat1 = _degToRad(latitude);
    final lat2 = _degToRad(other.latitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  bool isWithinRadiusKm(GeoLocation other, double radiusKm) {
    return distanceInKmTo(other) <= radiusKm;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  GeoLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, address];
}
