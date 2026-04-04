import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:geolocator/geolocator.dart'; // 📍 Live Location
import 'package:geocoding/geocoding.dart';   // 🗺️ Address Decoding

import 'booking_service.dart';
import 'booking_model.dart';
import '../Puja_Page/puja_model.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _service = BookingService();
  late Razorpay _razorpay;

  // 🕒 Booking Preferences
  DateTime? selectedDate;
  String? selectedTime;
  bool isSamagriIncluded = true;

  // 🔄 State Indicators
  bool isProcessing = false;
  String? errorMessage;

  Completer<bool>? _paymentCompleter;
  String? _currentBookingId;

  BookingProvider() {
    // Initialize Razorpay ONCE
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Default Date to Tomorrow
    selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _razorpay.clear(); // 🧹 Prevent Memory Leaks
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(false);
    }
    super.dispose();
  }

  // ==========================================
  // 🧮 DYNAMIC PRICING ENGINE (Industry Standard)
  // ==========================================

  // 🚀 DYNAMIC ADVANCE FETCH: Fetch exact platform fee directly from PujaModel
  double getAdvanceAmount(PujaModel puja) {
    // 🔥 FIX: Replaced hardcoded 101.0 with the actual platform fee from the PujaModel.
    // Ensure that your PujaModel has a property named `platformFee`.
    return puja.price.platformFee.toDouble();  }

  double _getSamagriPrice(PujaModel puja) {
    return puja.price.withSamagriTotal - puja.price.withoutSamagriTotal;
  }

  double calculateTotal(PujaModel puja) {
    double base = puja.price.withoutSamagriTotal;
    double samagri = isSamagriIncluded ? _getSamagriPrice(puja) : 0;
    double dynamicAdvance = getAdvanceAmount(puja);
    return base + samagri + dynamicAdvance;
  }

  // ==========================================
  // 📍 REAL-TIME LOCATION ENGINE (Zero-Lag)
  // ==========================================
  Future<Position> _getOptimizedPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services are disabled. Please enable GPS.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Location permissions are denied';
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied. Enable from settings.';
    }

    try {
      // 🚀 Don't wait forever. Timeout after 4 seconds!
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } on TimeoutException {
      // Fallback to last known location instantly
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw 'Location signal is too weak. Try moving near a window.';
    } catch (e) {
      throw 'Failed to fetch location. Please try again.';
    }
  }

  // ==========================================
  // 🎮 UI STATE MUTATORS
  // ==========================================
  void setDate(DateTime date) { selectedDate = date; notifyListeners(); }
  void setTime(String time) { selectedTime = time; notifyListeners(); }
  void toggleSamagri(bool val) { isSamagriIncluded = val; notifyListeners(); }

  void clearState() {
    selectedTime = null;
    errorMessage = null;
    isSamagriIncluded = true;
    selectedDate = DateTime.now().add(const Duration(days: 1));
    notifyListeners();
  }

  // ==========================================
  // 🚀 THE REAL BOOKING FLOW
  // ==========================================
  Future<bool> startBookingFlow(PujaModel puja) async {
    if (selectedDate == null || selectedTime == null) {
      errorMessage = "Please select a Date & Time for the Puja.";
      notifyListeners();
      return false;
    }

    // 🛡️ Safety: Cancel any dangling completers
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(false);
    }

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    _paymentCompleter = Completer<bool>();

    try {
      // 1. 📍 Get Optimized Location
      Position position = await _getOptimizedPosition();

      // 2. 🗺️ Decode Coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String realAddress = "Unknown Location";
      String realPincode = "";
      String realLandmark = "";

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        realAddress = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}".replaceAll(RegExp(r'^, |, $'), '');
        realPincode = place.postalCode ?? "";
        realLandmark = place.name ?? "";
      }

      final double samagriPrice = _getSamagriPrice(puja);
      final double dynamicPlatformFee = getAdvanceAmount(puja); // 🚀 Real Dynamic Fee Fetched

      // 3. 📦 Prepare Real Payload (100% Matching Backend Structure)
      final payload = {
        "pujaId": puja.id,
        "pujaName": puja.name,
        "samagriIncluded": isSamagriIncluded,
        "scheduledDate": selectedDate!.toIso8601String(),
        "scheduledTime": selectedTime,
        "coordinates": [position.longitude, position.latitude],
        "exactAddress": realAddress,
        "landmark": realLandmark,
        "pincode": realPincode,
        // 🔥 Keys updated to match backend API requirement
        "basePrice": puja.price.withoutSamagriTotal,
        "itemsPrice": samagriPrice, // Used 'itemsPrice' instead of 'samagriPrice'
        "platformFee": dynamicPlatformFee
      };

      // 4. Hit Node.js Backend
      final BookingInitResponse initRes = await _service.initPayment(payload);
      _currentBookingId = initRes.bookingId;

      // 5. Open Real Razorpay Checkout
      var options = {
        'key': 'rzp_test_SXtSXWXASpzI3H', // ⚠️ Ensure you replace this with your Prod Key
        'amount': initRes.amount,
        'name': 'ShubhNow Services',
        'description': '${puja.name} Advance Booking',
        'order_id': initRes.razorpayOrderId,
        'timeout': 180,
        'prefill': {
          'contact': '',
          'email': ''
        },
        'theme': { 'color': '#FF5722' }
      };

      _razorpay.open(options);

      return await _paymentCompleter!.future;

    } catch (e) {
      isProcessing = false;
      errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 🎧 RAZORPAY EVENT HANDLERS
  // ==========================================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      bool isVerified = await _service.verifyPayment(
        razorpayOrderId: response.orderId ?? "",
        razorpayPaymentId: response.paymentId ?? "",
        razorpaySignature: response.signature ?? "",
        bookingId: _currentBookingId ?? "",
      );

      if (isVerified) {
        if (!_paymentCompleter!.isCompleted) _paymentCompleter!.complete(true);
      } else {
        errorMessage = "Payment was successful but verification failed.";
        if (!_paymentCompleter!.isCompleted) _paymentCompleter!.complete(false);
      }
    } catch (e) {
      errorMessage = "Server error during payment verification.";
      if (!_paymentCompleter!.isCompleted) _paymentCompleter!.complete(false);
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isProcessing = false;
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = "Payment was cancelled.";
    } else {
      errorMessage = response.message ?? "Payment failed. Please try again.";
    }

    notifyListeners();
    if (!_paymentCompleter!.isCompleted) _paymentCompleter!.complete(false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    isProcessing = false;
    errorMessage = "External Wallets (${response.walletName}) are currently not supported directly.";
    notifyListeners();
    if (!_paymentCompleter!.isCompleted) _paymentCompleter!.complete(false);
  }
}

final bookingControllerProvider = ChangeNotifierProvider<BookingProvider>((ref) => BookingProvider());