import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  timeago.setLocaleMessages('es', timeago.EsMessages());

  // Si esto llega a fallar igual (proyecto mal configurado, etc.), la app
  // arranca igual y solo el push queda deshabilitado — ver
  // NotificationsService/PushService, que ya toleran Firebase ausente.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error) {
    debugPrint('No se pudo inicializar Firebase: $error');
  }

  runApp(const ProviderScope(child: PetTrackerApp()));
}
