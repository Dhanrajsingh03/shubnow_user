import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_constants.dart';
import '../../core/dio_client.dart';
// 🔥 TODO: Apne model ka sahi path verify kar lena
import 'login_model.dart';

class AuthService {
  // Network & Storage instances
  final Dio _dio = DioClient.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 📍 Backend Endpoints
  static const String _registerEndpoint = '/users/register';
  static const String _loginEndpoint = '/users/login';
  static const String _verifyOtpEndpoint = '/users/verify-otp';
  static const String _userProfileEndpoint = '/users/me';

  // ==========================================
  // 1. REGISTER: For new users
  // ==========================================
  Future<String> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(_registerEndpoint, data: {
        "fullName": fullName,
        "email": email,
        "phoneNumber": phoneNumber,
      });
      return response.data['message'] ?? 'OTP sent to your email';
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to register');
    }
  }

  // ==========================================
  // 2. LOGIN: For existing users
  // ==========================================
  Future<String> loginUser({required String email}) async {
    try {
      final response = await _dio.post(_loginEndpoint, data: {
        "email": email,
      });
      return response.data['message'] ?? 'OTP sent to your registered email';
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to login');
    }
  }

  // ==========================================
  // 3. VERIFY OTP & SAVE TOKENS (Industry Standard)
  // ==========================================
  Future<UserModel> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(_verifyOtpEndpoint, data: {
        "email": email,
        "otp": otp,
      });

      // Backend se user aur dono tokens nikaalo
      final userData = response.data['data']['user'];
      final String accessToken = response.data['data']['accessToken'];
      final String? refreshToken = response.data['data']['refreshToken'];

      // 🔥 Dono tokens ko Securely save karo
      await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: 'refreshToken', value: refreshToken);
      }

      print("✅ AUTH SUCCESS: Access & Refresh Tokens saved securely!");

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Invalid or Expired OTP');
    }
  }

  // ==========================================
  // 4. GET CURRENT USER (The Anti-Logout Fix)
  // ==========================================
  Future<UserModel> getUserProfile() async {
    try {
      final token = await _storage.read(key: ApiConstants.accessTokenKey);

      if (token == null || token.isEmpty) {
        throw Exception('No token found. User needs to login.');
      }

      final response = await _dio.get(
        _userProfileEndpoint,
        // Header interceptor khud laga dega, par safety ke liye yahan manual bhi de sakte ho:
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return UserModel.fromJson(response.data['data']);

    } on DioException catch (e) {
      // 🚀 THE FIX: Smart Error Handling taaki galat logout na ho

      // 1. Agar internet issue ya server down/slow hai
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Server is taking too long to respond. Please check your internet.');
      }

      // 2. Agar API Crash kar gayi (500) toh user ko token hata kar punish mat karo
      final statusCode = e.response?.statusCode;
      if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
        throw Exception('Server is currently under maintenance. We will be back soon!');
      }

      // 3. Sirf tab expire bolo jab strictly 401 (Unauthorized) aaye
      if (statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      // 4. Any other specific backend error message
      throw Exception(e.response?.data['message'] ?? 'An unknown network error occurred.');
    }
  }

  // ==========================================
  // 5. LOGOUT (Clear Secure Storage)
  // ==========================================
  Future<void> logout() async {
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: 'refreshToken'); // Delete both tokens!
    print("🔴 LOGGED OUT: All tokens wiped from Secure Storage.");
  }
}