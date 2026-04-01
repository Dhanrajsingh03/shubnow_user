import 'package:dio/dio.dart';
import '../../core/dio_client.dart'; // Tera secure Dio setup (Interceptors ke sath)
import 'booking_model.dart';

class BookingService {
  // 🚀 Base route for all User Booking APIs
  // Ensure your DioClient base URL is correct (e.g., http://your-ip:5000/api/v1)
  final String _baseRoute = '/bookings/user';

  // ==========================================
  // 💳 1. INITIALIZE PAYMENT (Create Booking + Razorpay Order)
  // ==========================================
  Future<BookingInitResponse> initPayment(Map<String, dynamic> bookingPayload) async {
    try {
      final response = await DioClient.instance.post(
        '$_baseRoute/init-payment',
        data: bookingPayload,
      );

      // Added 200 check as well just in case backend sends 200 instead of 201
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Automatically parse the nested Razorpay and Booking data
        return BookingInitResponse.fromJson(response.data);
      } else {
        throw Exception("Failed to initialize payment. Try again.");
      }
    } on DioException catch (e) {
      print("❌ Init Payment Error: ${e.message}");
      // Extract exact error message from Node.js backend
      throw Exception(e.response?.data['message'] ?? "Something went wrong while initiating booking.");
    } catch (e) {
      print("❌ Unknown Error: $e");
      throw Exception("An unexpected error occurred.");
    }
  }

  // ==========================================
  // 🛡️ 2. VERIFY PAYMENT (Signature Check & Radar Trigger)
  // ==========================================
  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String bookingId,
  }) async {
    try {
      final response = await DioClient.instance.post(
        '$_baseRoute/verify-payment',
        data: {
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
          "bookingId": bookingId,
        },
      );

      // Agar backend ne 200 OK diya, matlab payment verified aur Pandit dhoondhna shuru!
      if (response.statusCode == 200) {
        print("✅ Payment Verified by Backend!");
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("❌ Payment Verification Failed: ${e.response?.data['message']}");
      return false; // False return karenge taaki UI 'Failed' screen dikhaye
    } catch (e) {
      print("❌ Verification Crash: $e");
      return false;
    }
  }

  // ==========================================
  // 📜 3. FETCH USER BOOKINGS (With Smart Parser & Pagination)
  // ==========================================
  // 🚀 Returned List<dynamic> so it perfectly matches the FutureProvider in the UI
  Future<List<dynamic>> getUserBookings({
    int page = 1,
    int limit = 10,
    String? status // Optional filter (e.g., 'COMPLETED', 'ACCEPTED')
  }) async {
    try {
      // Dynamic Query Builder
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await DioClient.instance.get(
        '$_baseRoute/my-bookings',
        queryParameters: queryParams,
      );

      // 🔍 DEBUG PRINTS (Check your flutter console for this!)
      print("📦 RAW API RESPONSE STATUS: ${response.statusCode}");
      print("📦 RAW API RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200) {
        // 🧠 THE SMART PARSER
        // Ye check karega ki Node.js ne kis variable me data bheja hai
        var rawData = response.data['data'] ?? response.data;

        if (rawData == null) {
          return []; // Khali list bhej do
        } else if (rawData is List) {
          return rawData; // Agar seedha array hai, direct return karo
        } else if (rawData is Map) {
          // Pagination Wrapper checks (handles different mongoose pagination formats)
          if (rawData.containsKey('docs')) return rawData['docs'];
          if (rawData.containsKey('bookings')) return rawData['bookings'];
          if (rawData.containsKey('result')) return rawData['result'];
          if (rawData.containsKey('data')) return rawData['data']; // Nested safety
        }

        return []; // Fallback agar kuch match na ho
      } else {
        throw Exception("Failed to load booking history.");
      }
    } on DioException catch (e) {
      print("❌ Fetch Bookings Error: ${e.message}");
      throw Exception(e.response?.data['message'] ?? "Could not connect to the server.");
    } catch (e) {
      print("❌ Fetch Bookings Unknown Error: $e");
      throw Exception("An unexpected error occurred.");
    }
  }
}