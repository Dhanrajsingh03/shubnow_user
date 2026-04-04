import 'package:dio/dio.dart';
import '../../core/dio_client.dart'; // Tera secure Dio setup
import 'booking_model.dart';

class BookingService {
  // 🚀 Base route for all User Booking APIs
  // Ensure your DioClient base URL is correct (e.g., http://your-ip:5000/api/v1/bookings)
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

      // Backend sends an ApiResponse wrapper with 'success' and 'data'
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          // BookingInitResponse.fromJson will automatically handle data.booking & data.razorpayOrder
          return BookingInitResponse.fromJson(responseData);
        } else {
          throw Exception(responseData['message'] ?? "Failed to initialize payment.");
        }
      } else {
        throw Exception("Server returned ${response.statusCode}. Please try again.");
      }
    } on DioException catch (e) {
      print("❌ Init Payment Error: ${e.message}");
      // Extract exact error message from Node.js ApiError response
      throw Exception(e.response?.data['message'] ?? "Something went wrong while initiating booking.");
    } catch (e) {
      print("❌ Unknown Error: $e");
      throw Exception("An unexpected error occurred: $e");
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

      // Agar backend ne success: true diya, matlab payment verified aur Pandit dhoondhna shuru!
      if (response.statusCode == 200 && response.data['success'] == true) {
        print("✅ Payment Verified by Backend! Radar active.");
        return true;
      }

      print("⚠️ Backend Rejected Verification: ${response.data['message']}");
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
  // 📜 3. FETCH USER BOOKINGS (With Smart Extractors)
  // ==========================================
  Future<List<dynamic>> getUserBookings({
    int page = 1,
    int limit = 10,
    String? status
  }) async {
    try {
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

      if (response.statusCode == 200 && response.data['success'] == true) {
        // 🔥 EXACT PATH TO DATA: Tere backend ke hisaab se
        // response.data['data']['bookings'] mein array hai.

        final responseData = response.data['data'];

        if (responseData != null && responseData['bookings'] is List) {
          return responseData['bookings'];
        }

        return []; // Agar list null ho toh khali return karo
      } else {
        throw Exception(response.data['message'] ?? "Failed to load booking history.");
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