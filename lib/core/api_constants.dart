class ApiConstants {
  // 🌐 BASE URL
  // TODO: Jab live karoge, isko apne production server (AWS/DigitalOcean) ke URL se replace kar dena.
  // Local testing ke liye apna current IP/Ngrok use karo.
  static const String baseUrl = 'https://overexcitable-doretha-unbeclouded.ngrok-free.dev/api/v1';

  // ⏱️ NETWORK TIMEOUTS
  // Industry standard: 15 seconds. Agar user ka internet slow hai, toh app indefinite loading me nahi fasegi.
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // 🔐 LOCAL STORAGE KEYS
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String isUserLoggedInKey = 'isLoggedIn';
}