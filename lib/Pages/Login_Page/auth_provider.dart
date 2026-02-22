import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_constants.dart'; // 🔥 Apna sahi path daal lena
import 'auth_service.dart';
import 'login_model.dart';

// --- STATES ---
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthOtpSent extends AuthState {
  final String email;
  AuthOtpSent(this.email);
}

// 🚀 THE FIX: UserModel ko optional (nullable) banaya.
// Taaki server down hone par hum bina naye data ke bhi Home page khol sakein!
class AuthVerified extends AuthState {
  final UserModel? user;
  AuthVerified([this.user]); // Optional parameter
}

class AuthError extends AuthState {
  final String errorMessage;
  AuthError(this.errorMessage);
}

// --- PROVIDERS ---
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authServiceProvider));
});

// --- CONTROLLER ---
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthInitial());

  // 1. REGISTER
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

  // 2. LOGIN
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

  // 3. VERIFY OTP
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

  // 4. CHECK PERSISTENT SESSION (Called from Splash Screen)
  Future<void> checkSession() async {
    try {
      // 1. FAST LOCAL CHECK: Sabse pehle token check karo local storage se
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: ApiConstants.accessTokenKey);

      if (token == null || token.isEmpty) {
        if (mounted) state = AuthInitial();
        return; // Token nahi hai toh yahi se wapas Login pe bhej do
      }

      // 2. TOKEN HAI! Ab backend se fresh user data laane ki koshish karo
      final user = await _authService.getUserProfile();
      if (mounted) {
        state = AuthVerified(user); // Data aa gaya, Home pe bhej do
      }

    } catch (e) {
      final errorMessage = e.toString();

      // 🚀 THE INDUSTRY FIX: Check karo error kya hai?
      if (errorMessage.contains('Session expired') || errorMessage.contains('No token')) {
        // 🔥 SIRF TABHI LOGOUT KARO jab token sach mein expire ho (401 error)
        await _authService.logout();
        if (mounted) {
          state = AuthInitial();
        }
      } else {
        // 🔥 SERVER IS DOWN OR NO INTERNET!
        // Token local storage me already hai, toh logout MAT karo.
        // User ko Home page par bhej do bina nayi profile fetch kiye.
        print("Background fetch failed (Server Down/No Internet): $errorMessage");
        if (mounted) {
          state = AuthVerified(); // Null user pass hoga, par Home page makhhan khul jayega!
        }
      }
    }
  }

  // 5. MANUAL LOGOUT
  Future<void> logoutUser() async {
    state = AuthLoading();
    await _authService.logout();
    if (mounted) {
      state = AuthInitial(); // State reset, UI will redirect to Login
    }
  }

  // 6. RESET STATE (For UI toggles)
  void resetToInitial() {
    state = AuthInitial();
  }
}