// Smoke test: sin sesión guardada, la app debe redirigir a LoginScreen.
//
// Fakea FlutterSecureStoragePlatform en vez de dejar que ApiClient hable con
// el keyring real del sistema (dbus/libsecret) — en este entorno eso cuelga
// `pumpAndSettle` indefinidamente porque no hay un secret-service corriendo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pettracker/app.dart';

class _FakeSecureStorage extends FlutterSecureStoragePlatform {
  final _store = <String, String>{};

  @override
  Future<bool> containsKey({required String key, required Map<String, String> options}) async {
    return _store.containsKey(key);
  }

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async => _store.clear();

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    return _store[key];
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async {
    return Map.of(_store);
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    _store[key] = value;
  }
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = _FakeSecureStorage();
  });

  testWidgets('PetTrackerApp arranca y redirige a LoginScreen sin sesión guardada', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PetTrackerApp()));
    await tester.pumpAndSettle();

    expect(find.text('PetTracker'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });
}
