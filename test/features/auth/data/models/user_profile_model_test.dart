import 'package:flutter_test/flutter_test.dart';
import 'package:pettracker/features/auth/data/models/user_profile_model.dart';
import 'package:pettracker/shared/models/geo_location.dart';

void main() {
  group('UserProfileModel', () {
    final createdAt = DateTime.utc(2026, 1, 15, 8);

    final profile = UserProfileModel(
      uid: 'user-42',
      displayName: 'Marcos Quintana',
      email: 'marcosnoob27@gmail.com',
      photoUrl: 'https://example.com/avatar.jpg',
      phoneNumber: '+57 300 123 4567',
      lastKnownLocation: const GeoLocation(
        latitude: 4.710989,
        longitude: -74.072092,
        address: 'Bogotá, Colombia',
      ),
      notificationRadiusKm: 3.5,
      notificationsEnabled: true,
      fcmTokens: const ['token-a', 'token-b'],
      createdAt: createdAt,
    );

    // Forma real de una respuesta de GET /users/me del backend.
    final serverJson = {
      'id': profile.uid,
      'displayName': profile.displayName,
      'email': profile.email,
      'photoUrl': profile.photoUrl,
      'phoneNumber': profile.phoneNumber,
      'lastKnownLocation': {
        'latitude': 4.710989,
        'longitude': -74.072092,
        'address': 'Bogotá, Colombia',
      },
      'notificationRadiusKm': 3.5,
      'notificationsEnabled': true,
      'fcmTokens': ['token-a', 'token-b'],
      'createdAt': createdAt.toIso8601String(),
    };

    test('fromJson parsea la respuesta del backend correctamente', () {
      expect(UserProfileModel.fromJson(serverJson), profile);
    });

    test('toJson serializa sin id/createdAt (los asigna el backend)', () {
      final json = profile.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
      expect(json['notificationRadiusKm'], 3.5);
      expect(json['fcmTokens'], ['token-a', 'token-b']);
    });

    test('fromJson aplica defaults cuando faltan campos opcionales', () {
      final minimalJson = {'id': 'user-1', 'createdAt': createdAt.toIso8601String()};

      final restored = UserProfileModel.fromJson(minimalJson);

      expect(restored.notificationRadiusKm, 5.0);
      expect(restored.notificationsEnabled, isTrue);
      expect(restored.fcmTokens, isEmpty);
      expect(restored.lastKnownLocation, isNull);
    });

    test('copyWith solo cambia los campos indicados', () {
      final updated = profile.copyWith(notificationRadiusKm: 10);

      expect(updated.notificationRadiusKm, 10);
      expect(updated.uid, profile.uid);
      expect(updated.email, profile.email);
    });
  });
}
