// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

// ==========================================
// 🚦 1. ENUMS (For Type Safety & Clean Code)
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

// Extension to safely parse Enum from Backend String
extension BookingStatusExtension on String {
  BookingStatus toBookingStatus() {
    return BookingStatus.values.firstWhere(
          (e) => e.name == this,
      orElse: () => BookingStatus.UNKNOWN,
    );
  }

  PaymentStatus toPaymentStatus() {
    return PaymentStatus.values.firstWhere(
          (e) => e.name == this,
      orElse: () => PaymentStatus.UNKNOWN,
    );
  }
}

// ==========================================
// 📦 2. MAIN BOOKING MODEL (History & Tracking)
// ==========================================
class BookingModel {
  final String id; // MongoDB _id
  final String bookingId; // SN-123456
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
    required this.status,
    required this.isRated,
    required this.createdAt,
  });

  // 📥 JSON to Dart Object (With strict Null Safety)
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      panditId: json['pandit'] is String ? json['pandit'] : json['pandit']?['_id'], // Handles both populated and unpopulated
      pujaId: json['pujaId'],
      pujaName: json['pujaName'] ?? 'Unknown Puja',
      samagriIncluded: json['samagriIncluded'] ?? false,
      scheduledDate: DateTime.parse(json['scheduledDate'] ?? DateTime.now().toIso8601String()),
      scheduledTime: json['scheduledTime'] ?? '',
      location: BookingLocation.fromJson(json['location'] ?? {}),
      pricing: BookingPricing.fromJson(json['pricing'] ?? {}),
      payment: BookingPayment.fromJson(json['payment'] ?? {}),
      status: (json['status'] as String? ?? '').toBookingStatus(),
      isRated: json['isRated'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 📤 Dart Object to JSON (For sending to backend if needed)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'bookingId': bookingId,
      'pujaId': pujaId,
      'pujaName': pujaName,
      'samagriIncluded': samagriIncluded,
      'scheduledDate': scheduledDate.toIso8601String(),
      'scheduledTime': scheduledTime,
      'location': location.toJson(),
      'pricing': pricing.toJson(),
      'payment': payment.toJson(),
      'status': status.name,
      'isRated': isRated,
    };
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
        (coords[0] as num).toDouble(), // Longitude
        (coords[1] as num).toDouble(), // Latitude
      ],
      exactAddress: json['exactAddress'] ?? '',
      landmark: json['landmark'] ?? '',
      pincode: json['pincode'] ?? '',
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
// 💰 4. NESTED MODEL: PRICING
// ==========================================
class BookingPricing {
  final double basePrice;
  final double samagriPrice;
  final double discount;
  final double tax; // Platform Fee
  final double totalAmount;

  BookingPricing({
    required this.basePrice,
    required this.samagriPrice,
    required this.discount,
    required this.tax,
    required this.totalAmount,
  });

  factory BookingPricing.fromJson(Map<String, dynamic> json) {
    return BookingPricing(
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      samagriPrice: (json['samagriPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basePrice': basePrice,
      'samagriPrice': samagriPrice,
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
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
      method: json['method'] ?? 'ONLINE',
      status: (json['status'] as String? ?? '').toPaymentStatus(),
      transactionId: json['transactionId'] ?? '',
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
// 🚀 6. RESPONSE MODEL: RAZORPAY INIT
// ==========================================
class BookingInitResponse {
  final String bookingId;
  final String razorpayOrderId;
  final int amount; // Razorpay expects amount in paise (int)
  final String currency;

  BookingInitResponse({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
  });

  // Backend se jo /init-payment ka response aayega, ye use handle karega
  factory BookingInitResponse.fromJson(Map<String, dynamic> json) {
    final razorpayOrder = json['data']['razorpayOrder'];
    final booking = json['data']['booking'];

    return BookingInitResponse(
      bookingId: booking['_id'] ?? '',
      razorpayOrderId: razorpayOrder['id'] ?? '',
      amount: razorpayOrder['amount'] ?? 0,
      currency: razorpayOrder['currency'] ?? 'INR',
    );
  }
}