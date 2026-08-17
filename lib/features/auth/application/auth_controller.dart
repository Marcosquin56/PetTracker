import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/services/push_service.dart';
import '../../../shared/models/geo_location.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/user_profile_entity.dart';
import '../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider), ref.watch(apiClientProvider));
});

final pushServiceProvider = Provider<PushService>((ref) => const PushService());

final authControllerProvider = AsyncNotifierProvider<AuthController, UserProfileEntity?>(
  AuthController.new,
);

/// `state.value == null` significa "sin sesión"; distinto de `state.isLoading`
/// (verificando sesión guardada) o `state.hasError` (falló la verificación).
class AuthController extends AsyncNotifier<UserProfileEntity?> {
  @override
  Future<UserProfileEntity?> build() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user != null) unawaited(_registerPushToken());
    return user;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
    if (state.hasValue) unawaited(_registerPushToken());
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(email: email, password: password, displayName: displayName),
    );
    if (state.hasValue) unawaited(_registerPushToken());
  }

  /// Best-effort: si el usuario niega el permiso de notificaciones o falla
  /// la llamada al backend, no debe tumbar el login/registro.
  Future<void> _registerPushToken() async {
    try {
      final token = await ref.read(pushServiceProvider).requestPermissionAndGetToken();
      if (token != null) {
        await ref.read(authRepositoryProvider).registerFcmToken(token);
      }
    } catch (_) {
      // Push es una mejora, no un requisito para poder usar la app.
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    GeoLocation? lastKnownLocation,
    double? notificationRadiusKm,
    bool? notificationsEnabled,
  }) async {
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).updateProfile(
            displayName: displayName,
            photoUrl: photoUrl,
            phoneNumber: phoneNumber,
            lastKnownLocation: lastKnownLocation,
            notificationRadiusKm: notificationRadiusKm,
            notificationsEnabled: notificationsEnabled,
          ),
    );
  }

  Future<void> registerFcmToken(String token) async {
    final updated = await ref.read(authRepositoryProvider).registerFcmToken(token);
    state = AsyncData(updated);
  }
}
