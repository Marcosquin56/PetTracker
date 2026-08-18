import 'package:equatable/equatable.dart';

import '../../../../shared/models/geo_location.dart';

/// Detalle de una veterinaria (`GET /vets/:placeId`), pedido bajo demanda al
/// abrir el detalle en vez de por cada item del listado (cuida cuota/costo
/// del Places API — ver VetsService del backend).
class VetPlaceDetailEntity extends Equatable {
  const VetPlaceDetailEntity({
    required this.placeId,
    required this.name,
    required this.location,
    this.address,
    this.phone,
    this.openingHours,
    this.openNow,
  });

  final String placeId;
  final String name;
  final String? address;
  final GeoLocation location;
  final String? phone;
  final List<String>? openingHours;
  final bool? openNow;

  @override
  List<Object?> get props => [placeId, name, address, location, phone, openingHours, openNow];
}
