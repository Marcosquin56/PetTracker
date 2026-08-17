import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/user_profile_entity.dart';

/// DTO responsable de convertir entre [UserProfileEntity] y el JSON del
/// endpoint `/users/me` del backend propio.
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.uid,
    required super.createdAt,
    super.displayName,
    super.email,
    super.photoUrl,
    super.phoneNumber,
    super.lastKnownLocation,
    super.notificationRadiusKm,
    super.notificationsEnabled,
    super.fcmTokens,
  });

  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      uid: entity.uid,
      createdAt: entity.createdAt,
      displayName: entity.displayName,
      email: entity.email,
      photoUrl: entity.photoUrl,
      phoneNumber: entity.phoneNumber,
      lastKnownLocation: entity.lastKnownLocation,
      notificationRadiusKm: entity.notificationRadiusKm,
      notificationsEnabled: entity.notificationsEnabled,
      fcmTokens: entity.fcmTokens,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['lastKnownLocation'] as Map<String, dynamic>?;
    return UserProfileModel(
      uid: json['id'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      lastKnownLocation: rawLocation == null ? null : GeoLocation.fromJson(rawLocation),
      notificationRadiusKm: (json['notificationRadiusKm'] as num?)?.toDouble() ?? 5.0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      fcmTokens: List<String>.from((json['fcmTokens'] as List<dynamic>?) ?? const []),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (lastKnownLocation != null) 'lastKnownLocation': lastKnownLocation!.toJson(),
      'notificationRadiusKm': notificationRadiusKm,
      'notificationsEnabled': notificationsEnabled,
      'fcmTokens': fcmTokens,
    };
  }
}
