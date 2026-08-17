import 'package:flutter_test/flutter_test.dart';
import 'package:pettracker/shared/models/geo_location.dart';

void main() {
  group('GeoLocation', () {
    const bogota = GeoLocation(
      latitude: 4.710989,
      longitude: -74.072092,
      address: 'Bogotá, Colombia',
    );

    test('toJson/fromJson hace round-trip sin perder datos', () {
      final json = bogota.toJson();
      final restored = GeoLocation.fromJson(json);

      expect(restored, bogota);
    });

    test('fromJson funciona sin address', () {
      final json = {'latitude': 4.710989, 'longitude': -74.072092};

      final restored = GeoLocation.fromJson(json);

      expect(restored.latitude, bogota.latitude);
      expect(restored.longitude, bogota.longitude);
      expect(restored.address, isNull);
    });

    test('distanceInKmTo(self) es 0', () {
      expect(bogota.distanceInKmTo(bogota), 0);
    });

    test('distanceInKmTo calcula la distancia en línea recta Bogotá-Medellín (~239km)', () {
      // Nota: 239km es la distancia geodésica (línea recta); la distancia por
      // carretera es ~400km debido a la cordillera, pero Haversine mide la
      // primera, que es la relevante para "avistamientos cercanos".
      const medellin = GeoLocation(latitude: 6.244203, longitude: -75.581212);

      final distance = bogota.distanceInKmTo(medellin);

      expect(distance, closeTo(239, 5));
    });

    test('isWithinRadiusKm respeta el radio dado', () {
      const nearby = GeoLocation(latitude: 4.715, longitude: -74.075);

      expect(bogota.isWithinRadiusKm(nearby, 5), isTrue);
      expect(bogota.isWithinRadiusKm(nearby, 0.01), isFalse);
    });

    test('constructor rechaza coordenadas fuera de rango', () {
      expect(
        () => GeoLocation(latitude: 200, longitude: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
