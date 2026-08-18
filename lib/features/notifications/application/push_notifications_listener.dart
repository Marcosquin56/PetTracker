import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../chat/application/chat_providers.dart';

const _chatChannel = AndroidNotificationChannel(
  'chat_messages',
  'Mensajes de chat',
  description: 'Notificaciones de mensajes nuevos en tus chats.',
  importance: Importance.high,
);

final _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Efecto de una sola vez, sin estado propio: banner en primer plano cuando
/// llega un push, y navegar al chat correspondiente al tocarlo (en
/// background, terminada, o desde el banner). El envío en sí lo hace el
/// backend (NotificationsService); esto solo reacciona del lado cliente.
///
/// Se "activa" mirándolo una vez desde `PetTrackerApp` — no expone nada, el
/// puntito de no-leídos lo sigue manejando `unreadChatsCountProvider`.
final pushNotificationsSetupProvider = Provider<void>((ref) {
  unawaited(_setup(ref));
});

Future<void> _setup(Ref ref) async {
  try {
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_chatChannel);

    await _localNotificationsPlugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (response) {
        final conversationId = response.payload;
        if (conversationId != null) _openConversation(ref, conversationId);
      },
    );

    FirebaseMessaging.onMessage.listen((message) => _onForegroundMessage(ref, message));
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleTap(ref, message));

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleTap(ref, initialMessage);
  } catch (error) {
    // Mismo criterio que Firebase.initializeApp en main.dart: si esto falla
    // (permiso denegado, plugin no disponible, etc.) el resto de la app
    // sigue andando, solo sin push.
    debugPrint('No se pudo inicializar el manejo de notificaciones push: $error');
  }
}

/// Android no muestra el banner del sistema para el payload `notification`
/// mientras la app está en primer plano, así que lo mostramos nosotros con
/// flutter_local_notifications. De paso, si es un mensaje de chat,
/// refrescamos el inbox para que el puntito de no-leídos se actualice al
/// toque sin tener que reabrir la pestaña.
void _onForegroundMessage(Ref ref, RemoteMessage message) {
  if (message.data['type'] == 'chat') {
    ref.invalidate(conversationsProvider);
  }

  final notification = message.notification;
  if (notification == null) return;

  unawaited(
    _localNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(_chatChannel.id, _chatChannel.name, importance: Importance.high),
      ),
      payload: message.data['conversationId'] as String?,
    ),
  );
}

void _handleTap(Ref ref, RemoteMessage message) {
  final conversationId = message.data['conversationId'] as String?;
  if (message.data['type'] == 'chat' && conversationId != null) {
    _openConversation(ref, conversationId);
  }
}

void _openConversation(Ref ref, String conversationId) {
  ref.read(appRouterProvider).push('/chat/$conversationId');
}
