import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cliente HTTP hacia el backend propio (NestJS), con el JWT adjuntado
/// automáticamente a cada request.
///
/// Base URL configurable en build/run time, por ejemplo:
/// `flutter run --dart-define=API_BASE_URL=https://api.pettracker.app`.
/// El default `10.0.2.2` es el alias que usa el emulador de Android para
/// llegar al `localhost` de la máquina host durante desarrollo.
class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        dio = dio ?? Dio(BaseOptions(baseUrl: _defaultBaseUrl)) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await _secureStorage.read(key: _accessTokenKey);
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              final newAccessToken = await _handleUnauthorized(error);
              if (newAccessToken == null) {
                handler.next(error);
                return;
              }

              try {
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                handler.resolve(await this.dio.fetch<dynamic>(retryOptions));
              } on DioException catch (retryError) {
                handler.next(retryError);
              }
            },
          ),
        );
  }

  /// El access token dura poco (15 min por defecto, ver
  /// `JWT_ACCESS_EXPIRES_IN` del backend). Sin esto, cualquier sesión de más
  /// de 15 minutos empieza a recibir 401 y termina forzando un logout
  /// aunque el refresh token (30 días) siga siendo válido.
  ///
  /// Devuelve el nuevo access token si se pudo refrescar (para que quien
  /// llamó reintente su request), o `null` si no correspondía reintentar
  /// (no era un 401, ya se había reintentado, es el propio /auth/refresh, o
  /// el refresh token también es inválido — en ese caso sí hay que loguear
  /// al usuario de nuevo).
  Future<String?> _handleUnauthorized(DioException error) async {
    final requestOptions = error.requestOptions;
    final isAuthEndpoint = requestOptions.path.startsWith('/auth/');
    final alreadyRetried = requestOptions.extra['pettracker_retried'] == true;

    if (error.response?.statusCode != 401 || isAuthEndpoint || alreadyRetried) {
      return null;
    }
    requestOptions.extra['pettracker_retried'] = true;

    return _refreshAccessToken();
  }

  /// Varios requests pueden pisar un 401 al mismo tiempo (p. ej. el feed y
  /// la ubicación cargando en paralelo). El refresh token rota en cada uso
  /// del lado del backend, así que si cada request dispara su propio
  /// refresh, solo el primero en llegar es válido y el resto falla — por
  /// eso todos comparten el mismo Future en vuelo.
  Future<String?>? _refreshInFlight;

  Future<String?> _refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await readRefreshToken();
    if (refreshToken == null) return null;

    try {
      // Dio nuevo y sin interceptores: si usáramos `dio`, un 401 en esta
      // misma llamada volvería a pasar por este interceptor.
      final response = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final newAccessToken = response.data!['accessToken'] as String;
      final newRefreshToken = response.data!['refreshToken'] as String;
      await saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
      return newAccessToken;
    } on DioException {
      // Refresh token también vencido/inválido: no hay forma de recuperar
      // la sesión, hay que volver a pedir login.
      await clearTokens();
      return null;
    }
  }

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const _accessTokenKey = 'pettracker_access_token';
  static const _refreshTokenKey = 'pettracker_refresh_token';

  final Dio dio;
  final FlutterSecureStorage _secureStorage;

  /// Para clientes que no usan Dio (p. ej. el socket del chat), que arman su
  /// propia URL de conexión a partir de la misma base configurada acá.
  String get baseUrl => dio.options.baseUrl;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _secureStorage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _secureStorage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
