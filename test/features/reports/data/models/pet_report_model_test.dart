import 'package:flutter_test/flutter_test.dart';
import 'package:pettracker/features/reports/data/models/pet_report_model.dart';
import 'package:pettracker/features/reports/domain/entities/enums/health_condition.dart';
import 'package:pettracker/features/reports/domain/entities/enums/pet_species.dart';
import 'package:pettracker/features/reports/domain/entities/enums/report_status.dart';
import 'package:pettracker/shared/models/geo_location.dart';

void main() {
  group('PetReportModel', () {
    final createdAt = DateTime.utc(2026, 8, 1, 10, 30);
    final updatedAt = DateTime.utc(2026, 8, 2, 9);

    final report = PetReportModel(
      id: 'report-1',
      reporterId: 'user-42',
      species: PetSpecies.dog,
      status: ReportStatus.stray,
      healthConditions: const [HealthCondition.injured, HealthCondition.hasCollar],
      photoUrls: const ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
      location: const GeoLocation(
        latitude: 4.710989,
        longitude: -74.072092,
        address: 'Bogotá, Colombia',
      ),
      petName: 'Rocky',
      breed: 'Mestizo',
      color: 'Negro',
      description: 'Cojea de la pata trasera derecha.',
      contactPhone: '+57 300 123 4567',
      createdAt: createdAt,
      updatedAt: updatedAt,
      isResolved: false,
    );

    // Forma real de una respuesta de GET /reports/:id del backend.
    final serverJson = {
      'id': report.id,
      'reporterId': report.reporterId,
      'species': 'dog',
      'status': 'stray',
      'healthConditions': ['injured', 'has_collar'],
      'photoUrls': report.photoUrls,
      'location': {
        'latitude': 4.710989,
        'longitude': -74.072092,
        'address': 'Bogotá, Colombia',
      },
      'petName': 'Rocky',
      'breed': 'Mestizo',
      'color': 'Negro',
      'description': 'Cojea de la pata trasera derecha.',
      'contactPhone': '+57 300 123 4567',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isResolved': false,
    };

    test('fromJson parsea la respuesta del backend correctamente', () {
      expect(PetReportModel.fromJson(serverJson), report);
    });

    test('toJson serializa enums usando su apiValue estable, sin id/timestamps', () {
      final json = report.toJson();

      expect(json['species'], 'dog');
      expect(json['status'], 'stray');
      expect(json['healthConditions'], ['injured', 'has_collar']);
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
    });

    test('fromJson usa valores por defecto para campos opcionales ausentes', () {
      final minimalJson = {
        'id': 'report-2',
        'reporterId': 'user-1',
        'species': 'cat',
        'status': 'lost',
        'photoUrls': <String>[],
        'location': {'latitude': 4.710989, 'longitude': -74.072092},
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

      final restored = PetReportModel.fromJson(minimalJson);

      expect(restored.healthConditions, isEmpty);
      expect(restored.isResolved, isFalse);
      expect(restored.petName, isNull);
    });

    test('primaryPhotoUrl retorna la primera foto', () {
      expect(report.primaryPhotoUrl, 'https://example.com/photo1.jpg');
    });

    test('distanceFromKm(self) es 0', () {
      expect(report.distanceFromKm(report.location), 0);
    });
  });
}
