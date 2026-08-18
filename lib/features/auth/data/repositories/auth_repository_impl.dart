import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/geo_location.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._apiClient);

  final AuthRemoteDataSource _remote;
  final ApiClient _apiClient;

  @override
  Future<UserProfileEntity> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final tokens = await _remote.register(email: email, password: password, displayName: displayName);
    await _apiClient.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    return _remote.getMe();
  }

  @override
  Future<UserProfileEntity> login({required String email, required String password}) async {
    final tokens = await _remote.login(email: email, password: password);
    await _apiClient.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    return _remote.getMe();
  }

  @override
  Future<void> logout() => _apiClient.clearTokens();

  @override
  Future<void> forgotPassword(String email) => _remote.forgotPassword(email);

  @override
  Future<UserProfileEntity?> getCurrentUser() async {
    final token = await _apiClient.readAccessToken();
    if (token == null) return null;

    try {
      return await _remote.getMe();
    } on DioException {
      // Token guardado pero ya no válido (expiró, usuario borrado, etc.).
      await _apiClient.clearTokens();
      return null;
    }
  }

  @override
  Future<UserProfileEntity> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    GeoLocation? lastKnownLocation,
    double? notificationRadiusKm,
    bool? notificationsEnabled,
  }) {
    return _remote.updateMe({
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (lastKnownLocation != null) 'lastKnownLocation': lastKnownLocation.toJson(),
      if (notificationRadiusKm != null) 'notificationRadiusKm': notificationRadiusKm,
      if (notificationsEnabled != null) 'notificationsEnabled': notificationsEnabled,
    });
  }

  @override
  Future<UserProfileEntity> registerFcmToken(String token) => _remote.addFcmToken(token);

  @override
  Future<UserProfileEntity> updatePhoto(XFile photo) => _remote.updateMyPhoto(photo);
}
