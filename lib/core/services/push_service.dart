import 'package:firebase_messaging/firebase_messaging.dart';

/// Wrapper sobre `firebase_messaging`: solo pide permiso y expone el token
/// del dispositivo. El envío de push lo hace el backend (`firebase-admin`);
/// el cliente nunca habla con Firestore/Storage/Auth.
class PushService {
  const PushService();

  /// `null` si el usuario niega el permiso de notificaciones.
  Future<String?> requestPermissionAndGetToken() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    return messaging.getToken();
  }
}
