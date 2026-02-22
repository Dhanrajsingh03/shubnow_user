import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// 🔥 TODO: Apne api_constants.dart ka sahi path daal lena
import 'api_constants.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(AuthInterceptor()); // 🛡️ Interceptor/Guard lag gaya

  static Dio get instance => _dio;
}

// =========================================================================
// 🛡️ AUTH INTERCEPTOR: The Ultimate Background Token Manager
// =========================================================================
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 🔥 Naya Dio instance sirf refresh API ke liye taaki infinite loop na bane
  final Dio _tokenDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  bool _isRefreshing = false;
  // Agar ek sath multiple requests aati hain, toh unko is list me hold/pause karenge
  final List<Map<String, dynamic>> _failedRequestsQueue = [];

  // --- ⬆️ ON REQUEST: Har API call se pehle token check aur attach karega ---
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Secure Storage se Access Token read karo
    final accessToken = await _storage.read(key: ApiConstants.accessTokenKey);

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  // --- ⬇️ ON ERROR: Token Expire hone par background magic karega ---
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Agar error 401 (Unauthorized) hai, iska matlab token expire ho gaya hai
    if (err.response?.statusCode == 401) {

      final refreshToken = await _storage.read(key: 'refreshToken');

      // Agar Refresh Token hi nahi hai, toh app mein rehne ka koi matlab nahi
      if (refreshToken == null || refreshToken.isEmpty) {
        await _performLogout();
        return handler.next(err);
      }

      // 🔴 REFRESH LOGIC START
      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          // 1. Backend se naya token maango
          final response = await _tokenDio.post(
            '/users/refresh-token',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            // 2. Naya token nikaalo aur Secure Storage me daalo
            final newAccessToken = response.data['data']['accessToken'];
            final newRefreshToken = response.data['data']['refreshToken'];

            await _storage.write(key: ApiConstants.accessTokenKey, value: newAccessToken);
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await _storage.write(key: 'refreshToken', value: newRefreshToken);
            }

            // 3. Queue mein ruki hui SAARI requests ko naye token ke sath Retry karo
            for (var queuedRequest in _failedRequestsQueue) {
              final options = queuedRequest['options'] as RequestOptions;
              final qHandler = queuedRequest['handler'] as ErrorInterceptorHandler;

              options.headers['Authorization'] = 'Bearer $newAccessToken';
              try {
                final retryResponse = await _tokenDio.fetch(options);
                qHandler.resolve(retryResponse); // Seamlessly user ko data de do
              } catch (e) {
                qHandler.reject(e as DioException);
              }
            }
            _failedRequestsQueue.clear();
            _isRefreshing = false;

            // 4. Current fail hui request (jisne error trigger kiya) ko bhi Retry karo
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await _tokenDio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          // 🛑 REFRESH API FAILED
          _isRefreshing = false;
          _failedRequestsQueue.clear();

          // 🔥 LATEST FIX: Agar server down (500) ya timeout hai, toh LOGOUT MAT KARO!
          // Sirf tab logout karo jab backend strictly bole ki Refresh Token expire (401/403) ho gaya hai.
          if (e is DioException) {
            final statusCode = e.response?.statusCode;
            if (statusCode == 401 || statusCode == 403) {
              await _performLogout();
            }
          }

          return handler.next(err);
        }
      } else {
        // Agar pehle se koi aur request naya token la rahi hai, toh is failed request ko line me lagao
        _failedRequestsQueue.add({'options': err.requestOptions, 'handler': handler});
        return;
      }
    }

    // Agar error 401 nahi hai (jaise 404, 500, ya No Internet), toh directly aage bhej do
    return handler.next(err);
  }

  // --- 🚪 LOGOUT UTILITY ---
  Future<void> _performLogout() async {
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: 'refreshToken');
    print("🔴 SESSION EXPIRED: User securely logged out. Tokens wiped.");
    // Note: Riverpod AuthState listener (jo splash me lagaya tha) isse detect karke
    // user ko automatically Onboarding/Login screen par bhej dega.
  }
}