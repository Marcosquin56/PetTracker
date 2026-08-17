import 'package:equatable/equatable.dart';

import '../../../../shared/models/geo_location.dart';

/// Representación de dominio de un usuario de PetTracker.
///
/// Se guarda por separado del `User` de Firebase Auth: Auth resuelve
/// identidad/credenciales, este perfil resuelve preferencias de notificación
/// y datos visibles en la app (colección `users` en Firestore).
class UserProfileEntity extends Equatable {
  const UserProfileEntity({
    required this.uid,
    required this.createdAt,
    this.displayName,
    this.email,
    this.photoUrl,
    this.phoneNumber,
    this.lastKnownLocation,
    this.notificationRadiusKm = 5.0,
    this.notificationsEnabled = true,
    this.fcmTokens = const [],
  });

  /// UID de Firebase Auth; también es el ID del documento en Firestore.
  final String uid;

  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? phoneNumber;

  /// Última ubicación conocida, usada para calcular distancias en el feed y
  /// para decidir a quién notificar cuando aparece un reporte cercano.
  final GeoLocation? lastKnownLocation;

  /// Radio (km) dentro del cual el usuario quiere recibir notificaciones
  /// push de nuevos avistamientos.
  final double notificationRadiusKm;
  final bool notificationsEnabled;

  /// Tokens FCM del dispositivo(s) del usuario, para el envío de push.
  final List<String> fcmTokens;

  final DateTime createdAt;

  UserProfileEntity copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    GeoLocation? lastKnownLocation,
    double? notificationRadiusKm,
    bool? notificationsEnabled,
    List<String>? fcmTokens,
  }) {
    return UserProfileEntity(
      uid: uid,
      createdAt: createdAt,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      notificationRadiusKm: notificationRadiusKm ?? this.notificationRadiusKm,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        email,
        photoUrl,
        phoneNumber,
        lastKnownLocation,
        notificationRadiusKm,
        notificationsEnabled,
        fcmTokens,
        createdAt,
      ];
}
