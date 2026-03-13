import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_constants.dart'; // 🔥 Path check kar lena
import '../../core/dio_client.dart';   // 🔥 Path check kar lena
import 'login_model.dart';

class AuthService {
  // Instances for Network & Storage
  final Dio _dio = DioClient.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 📍 Backend Endpoints based on your routes
  static const String _registerEndpoint = '/users/register';
  static const String _loginEndpoint = '/users/login';
  static const String _verifyOtpEndpoint = '/users/verify-otp';
  static const String _userProfileEndpoint = '/users/me';
  static const String _syncLocationEndpoint = '/users/sync-location';

  // ==========================================
  // 1. REGISTER: Naye user ke liye 📝
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
  // 2. LOGIN: Purane user ke liye (Email flow) 🔑
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
  // 3. VERIFY OTP: Tokens save karne ke liye ✅
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

      // Backend response structure check
      final userData = response.data['data']['user'];
      final String accessToken = response.data['data']['accessToken'];
      final String? refreshToken = response.data['data']['refreshToken'];

      // 🔥 Tokens ko Securely save karo
      await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: 'refreshToken', value: refreshToken);
      }

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Invalid or Expired OTP');
    }
  }

  // ==========================================
  // 4. GET PROFILE: Auto-login session ke liye 👤
  // ==========================================
  Future<UserModel> getUserProfile() async {
    try {
      // Backend route provides user profile
      final response = await _dio.get(_userProfileEndpoint);
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      // 401 matlab session gaya
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch profile.');
    }
  }

  // ==========================================
  // 5. SYNC LIVE LOCATION: Real-time update 📍
  // ==========================================
  Future<void> syncLocation(double lat, double lng) async {
    try {
      // Backend expects { lat, lng } in body
      // And route is PATCH /users/sync-location
      await _dio.patch(_syncLocationEndpoint, data: {
        'lat': lat,
        'lng': lng,
      });
      print("✅ Geolocation Synced: $lat, $lng");
    } on DioException catch (e) {
      // Silent error for location taaki UI na tute
      print("❌ Sync Error: ${e.response?.data['message']}");
    }
  }

  // ==========================================
  // 6. LOGOUT: Storage clear karne ke liye 🔴
  // ==========================================
  Future<void> logout() async {
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: 'refreshToken');
    print("🔴 Auth Session Cleared Locally.");
  }
}