import 'package:geolocator/geolocator.dart';

import '../../shared/models/geo_location.dart';

/// Wrapper sobre `geolocator`: pide permisos y resuelve la ubicación actual
/// como [GeoLocation], para no filtrar el tipo `Position` de geolocator al
/// resto de la app.
class LocationService {
  const LocationService();

  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Pide permiso si aún no se ha concedido. Devuelve `false` si el usuario
  /// lo niega o si el servicio de ubicación del dispositivo está apagado.
  Future<bool> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// `null` si no hay permiso o el usuario lo niega al pedirlo.
  Future<GeoLocation?> getCurrentLocation() async {
    if (!await requestPermission()) return null;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return GeoLocation(latitude: position.latitude, longitude: position.longitude);
  }
}
