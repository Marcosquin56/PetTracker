import '../../../../shared/models/geo_location.dart';
import '../entities/user_profile_entity.dart';

abstract class AuthRepository {
  Future<UserProfileEntity> register({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserProfileEntity> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> forgotPassword(String email);

  /// `null` si no hay una sesión guardada (o el token guardado ya no sirve).
  Future<UserProfileEntity?> getCurrentUser();

  Future<UserProfileEntity> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    GeoLocation? lastKnownLocation,
    double? notificationRadiusKm,
    bool? notificationsEnabled,
  });

  Future<UserProfileEntity> registerFcmToken(String token);
}
