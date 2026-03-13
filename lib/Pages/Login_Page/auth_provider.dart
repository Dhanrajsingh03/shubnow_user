import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_constants.dart'; // 🔥 Path check kar lena
import 'auth_service.dart';
import 'login_model.dart';

// ==========================================
// 🏗️ 1. AUTH STATES
// ==========================================
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String email;
  AuthOtpSent(this.email);
}

// 🚀 THE INDUSTRY FIX: UserModel ko optional (nullable) rakha hai.
// Taaki agar server down ho ya internet na ho, tab bhi session persisted rahe.
class AuthVerified extends AuthState {
  final UserModel? user;
  AuthVerified([this.user]);
}

class AuthError extends AuthState {
  final String errorMessage;
  AuthError(this.errorMessage);
}

// ==========================================
// 🛰️ 2. PROVIDERS
// ==========================================
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authServiceProvider));
});

// ==========================================
// 🕹️ 3. CONTROLLER (StateNotifier)
// ==========================================
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthInitial());

  // --- A. REGISTER ---
  Future<void> register({required String fullName, required String email, required String phoneNumber}) async {
    state = AuthLoading();
    try {
      await _authService.registerUser(fullName: fullName, email: email, phoneNumber: phoneNumber);
      state = AuthOtpSent(email);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
      Future.delayed(const Duration(milliseconds: 100), () => state = AuthInitial());
    }
  }

  // --- B. LOGIN ---
  Future<void> login({required String email}) async {
    state = AuthLoading();
    try {
      await _authService.loginUser(email: email);
      state = AuthOtpSent(email);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
      Future.delayed(const Duration(milliseconds: 100), () => state = AuthInitial());
    }
  }

  // --- C. VERIFY OTP ---
  Future<void> verifyOtp({required String email, required String otp}) async {
    state = AuthLoading();
    try {
      final user = await _authService.verifyOtp(email: email, otp: otp);
      state = AuthVerified(user);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) state = AuthOtpSent(email);
      });
    }
  }

  // --- D. CHECK PERSISTENT SESSION ---
  Future<void> checkSession() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: ApiConstants.accessTokenKey);

      if (token == null || token.isEmpty) {
        if (mounted) state = AuthInitial();
        return;
      }

      // Fresh data laane ki koshish karo
      final user = await _authService.getUserProfile();
      if (mounted) state = AuthVerified(user);

    } catch (e) {
      final errorMessage = e.toString();
      // Sirf strictly 401 (Unauthorized) par logout karo
      if (errorMessage.contains('Session expired')) {
        await _authService.logout();
        if (mounted) state = AuthInitial();
      } else {
        // No Internet / Server issue: Allow Home Access with local session
        if (mounted) state = AuthVerified();
      }
    }
  }

  // ==========================================
  // 📍 E. SYNC LIVE LOCATION (INDUSTRY LEVEL)
  // ==========================================
  Future<void> updateLiveLocation(double lat, double lng) async {
    try {
      // Direct call to hit PATCH /users/sync-location
      await _authService.syncLocation(lat, lng);
      print("✅ Background Sync: Location updated successfully ($lat, $lng)");
    } catch (e) {
      // Silent Error: User ko pareshaan nahi karenge
      print("❌ Sync Warning: $e");
    }
  }

  // --- F. MANUAL LOGOUT ---
  Future<void> logoutUser() async {
    state = AuthLoading();
    await _authService.logout();
    if (mounted) state = AuthInitial();
  }

  // --- G. RESET STATE ---
  void resetToInitial() {
    state = AuthInitial();
  }
}