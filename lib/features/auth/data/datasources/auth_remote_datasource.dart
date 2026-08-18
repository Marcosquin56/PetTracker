import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile_model.dart';

typedef TokenPair = ({String accessToken, String refreshToken});

/// Llamadas HTTP crudas a `/auth/*` y `/users/me` del backend propio.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TokenPair> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        if (displayName != null) 'displayName': displayName,
      },
    );
    return _toTokenPair(response.data!);
  }

  Future<TokenPair> login({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _toTokenPair(response.data!);
  }

  /// El backend siempre responde OK (no revela si el email existe); errores
  /// acá son solo de red/servidor, no "email no encontrado".
  Future<void> forgotPassword(String email) async {
    await _dio.post<Map<String, dynamic>>('/auth/forgot-password', data: {'email': email});
  }

  Future<UserProfileModel> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/users/me');
    return UserProfileModel.fromJson(response.data!);
  }

  Future<UserProfileModel> updateMe(Map<String, dynamic> patch) async {
    final response = await _dio.patch<Map<String, dynamic>>('/users/me', data: patch);
    return UserProfileModel.fromJson(response.data!);
  }

  Future<UserProfileModel> updateMyPhoto(XFile photo) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(photo.path, filename: photo.name),
    });
    final response = await _dio.post<Map<String, dynamic>>('/users/me/photo', data: formData);
    return UserProfileModel.fromJson(response.data!);
  }

  Future<UserProfileModel> addFcmToken(String token) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/users/me/fcm-tokens',
      data: {'token': token},
    );
    return UserProfileModel.fromJson(response.data!);
  }

  TokenPair _toTokenPair(Map<String, dynamic> json) {
    return (accessToken: json['accessToken'] as String, refreshToken: json['refreshToken'] as String);
  }
}
