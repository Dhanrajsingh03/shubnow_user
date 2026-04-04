// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

// ==========================================
// 🚦 1. ENUMS (Strict Type Safety)
// ==========================================
enum BookingStatus {
  PAYMENT_PENDING,
  SEARCHING_PANDIT,
  ACCEPTED,
  EN_ROUTE,
  IN_PROGRESS,
  COMPLETED,
  CANCELLED,
  UNKNOWN
}

enum PaymentStatus {
  PENDING,
  COMPLETED,
  FAILED,
  REFUNDED,
  UNKNOWN
}

// 🧠 Smart Extension to safely parse Enum from Node.js String
extension BookingStatusExtension on String {
  BookingStatus toBookingStatus() {
    return BookingStatus.values.firstWhere(
          (e) => e.name.toUpperCase() == toUpperCase().trim(),
      orElse: () => BookingStatus.UNKNOWN,
    );
  }

  PaymentStatus toPaymentStatus() {
    return PaymentStatus.values.firstWhere(
          (e) => e.name.toUpperCase() == toUpperCase().trim(),
      orElse: () => PaymentStatus.UNKNOWN,
    );
  }
}

// ==========================================
// 📦 2. MAIN BOOKING MODEL (Synced with Mongoose)
// ==========================================
class BookingModel {
  final String id; // MongoDB _id
  final String bookingId; // e.g., SN-123456
  final String? panditId;
  final String? pujaId;
  final String pujaName;
  final bool samagriIncluded;
  final DateTime scheduledDate;
  final String scheduledTime;

  // Nested Objects
  final BookingLocation location;
  final BookingPricing pricing;
  final BookingPayment payment;
  final BookingCancellation? cancellation; // Added for cancellation tracking

  final BookingStatus status;
  final bool isRated;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.bookingId,
    this.panditId,
    this.pujaId,
    required this.pujaName,
    required this.samagriIncluded,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.location,
    required this.pricing,
    required this.payment,
    this.cancellation,
    required this.status,
    required this.isRated,
    required this.createdAt,
  });

  // 📥 JSON to Dart Object (Smart Population Handling)
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',

      // Smart Check: Backend can send either Object (populate) or String ID
      panditId: json['pandit'] is Map ? json['pandit']['_id'] : json['pandit']?.toString(),
      pujaId: json['pujaId'] is Map ? json['pujaId']['_id'] : json['pujaId']?.toString(),

      pujaName: json['pujaName']?.toString() ?? 'Unknown Puja',
      samagriIncluded: json['samagriIncluded'] ?? false,
      scheduledDate: DateTime.tryParse(json['scheduledDate'] ?? '') ?? DateTime.now(),
      scheduledTime: json['scheduledTime']?.toString() ?? '',

      location: BookingLocation.fromJson(json['location'] ?? {}),
      pricing: BookingPricing.fromJson(json['pricing'] ?? {}),
      payment: BookingPayment.fromJson(json['payment'] ?? {}),
      cancellation: json['cancellation'] != null ? BookingCancellation.fromJson(json['cancellation']) : null,

      status: (json['status'] as String? ?? '').toBookingStatus(),
      isRated: json['isRated'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// ==========================================
// 📍 3. NESTED MODEL: LOCATION
// ==========================================
class BookingLocation {
  final List<double> coordinates; // [longitude, latitude]
  final String exactAddress;
  final String landmark;
  final String pincode;

  BookingLocation({
    required this.coordinates,
    required this.exactAddress,
    required this.landmark,
    required this.pincode,
  });

  factory BookingLocation.fromJson(Map<String, dynamic> json) {
    List<dynamic> coords = json['coordinates'] ?? [0.0, 0.0];
    return BookingLocation(
      coordinates: [
        (coords.isNotEmpty ? coords[0] as num : 0).toDouble(), // Longitude
        (coords.length > 1 ? coords[1] as num : 0).toDouble(), // Latitude
      ],
      exactAddress: json['exactAddress']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'Point',
      'coordinates': coordinates,
      'exactAddress': exactAddress,
      'landmark': landmark,
      'pincode': pincode,
    };
  }
}

// ==========================================
// 💰 4. NESTED MODEL: PRICING (🔥 FIXED KEYS TO MATCH BACKEND 🔥)
// ==========================================
class BookingPricing {
  final double basePrice;
  final double itemsPrice;   // Was samagriPrice
  final double platformFee;  // Was tax
  final double discount;
  final double totalPrice;   // Was totalAmount

  BookingPricing({
    required this.basePrice,
    required this.itemsPrice,
    required this.platformFee,
    required this.discount,
    required this.totalPrice,
  });

  factory BookingPricing.fromJson(Map<String, dynamic> json) {
    return BookingPricing(
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      itemsPrice: (json['itemsPrice'] as num?)?.toDouble() ?? 0.0,     // Fixed Key
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,   // Fixed Key
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,     // Fixed Key
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basePrice': basePrice,
      'itemsPrice': itemsPrice,
      'platformFee': platformFee,
      'discount': discount,
      'totalPrice': totalPrice,
    };
  }
}

// ==========================================
// 💳 5. NESTED MODEL: PAYMENT
// ==========================================
class BookingPayment {
  final String method;
  final PaymentStatus status;
  final String transactionId;

  BookingPayment({
    required this.method,
    required this.status,
    required this.transactionId,
  });

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      method: json['method']?.toString() ?? 'ONLINE',
      status: (json['status'] as String? ?? '').toPaymentStatus(),
      transactionId: json['transactionId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'status': status.name,
      'transactionId': transactionId,
    };
  }
}

// ==========================================
// 🚫 6. NESTED MODEL: CANCELLATION
// ==========================================
class BookingCancellation {
  final String? cancelledBy; // "USER", "PANDIT", "ADMIN", or null
  final String reason;

  BookingCancellation({
    this.cancelledBy,
    required this.reason,
  });

  factory BookingCancellation.fromJson(Map<String, dynamic> json) {
    return BookingCancellation(
      cancelledBy: json['cancelledBy']?.toString(),
      reason: json['reason']?.toString() ?? '',
    );
  }
}

// ==========================================
// 🚀 7. RESPONSE MODEL: RAZORPAY INIT
// ==========================================
class BookingInitResponse {
  final String bookingId;
  final String razorpayOrderId;
  final int amount;
  final String currency;

  BookingInitResponse({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
  });

  factory BookingInitResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final razorpayOrder = data['razorpayOrder'] ?? {};
    final booking = data['booking'] ?? {};

    return BookingInitResponse(
      bookingId: booking['_id']?.toString() ?? '',
      razorpayOrderId: razorpayOrder['id']?.toString() ?? '',
      amount: (razorpayOrder['amount'] as num?)?.toInt() ?? 0,
      currency: razorpayOrder['currency']?.toString() ?? 'INR',
    );
  }
}