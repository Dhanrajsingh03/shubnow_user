import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'booking_provider.dart';
import '../Puja_Page/puja_model.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  final PujaModel puja;
  const BookingSummaryScreen({super.key, required this.puja});

  @override
  ConsumerState<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  // 🌟 Premium Button Scale State
  double _buttonScale = 1.0;

  // ==========================================
  // 🚀 REAL PAYMENT EXECUTION LOGIC (Zero-Lag)
  // ==========================================
  void _executePayment() async {
    // Instant haptic feedback on touch release
    HapticFeedback.lightImpact();

    final provider = ref.read(bookingControllerProvider.notifier);

    // Ye async call background me chalegi, UI turant morph ho jayega
    bool isSuccess = await provider.startBookingFlow(widget.puja);

    if (isSuccess && mounted) {
      _showPremiumSuccessDialog();
    } else if (mounted) {
      final errorMsg = ref.read(bookingControllerProvider).errorMessage ?? "Payment Failed!";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red.shade800),
      );
    }
  }

  // 🌟 THE PREMIUM SUCCESS ANIMATION OVERLAY
  void _showPremiumSuccessDialog() {
    HapticFeedback.heavyImpact();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8 * a1.value, sigmaY: 8 * a1.value),
          child: FadeTransition(
            opacity: a1,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: a1, curve: Curves.elasticOut),
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                content: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 15))]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: const CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check_rounded, color: Colors.white, size: 45),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text("Payment Successful!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text("Your booking is confirmed.", style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // 🚀 REDIRECTION LOGIC UPDATED HERE
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pop(); // Popup ko close karo pehle
        context.goNamed('my-bookings'); // 🚀 Seedha "My Bookings" page par redirect!
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(bookingControllerProvider);
    final providerNotifier = ref.read(bookingControllerProvider.notifier);
    final puja = widget.puja;

    // 🧮 CALCULATIONS FOR SPLIT PAYMENT
    final double basePrice = puja.price.withoutSamagriTotal;
    final double samagriPrice = puja.price.withSamagriTotal - puja.price.withoutSamagriTotal;
    final double selectedSamagriPrice = providerState.isSamagriIncluded ? samagriPrice : 0;

    final double payableToPandit = basePrice + selectedSamagriPrice;
    final double payableNow = providerState.platformFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
            ),
          ),
        ),
        title: const Text("Checkout", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 🛒 1. ITEM SUMMARY CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(puja.image, height: 75, width: 75, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                          child: const Text("VERIFIED PANDIT", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 6),
                        Text(puja.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text(puja.title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🎁 2. PREMIUM PACKAGE SELECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Package", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.3)),
                  const SizedBox(height: 12),

                  if (puja.isWithSamagriAvailable)
                    _buildPackageCard(
                      title: "Premium (Pooja + Samagri)",
                      subtitle: "Pandit ji brings all fresh samagri & flowers.",
                      price: puja.price.withSamagriTotal,
                      isSelected: providerState.isSamagriIncluded,
                      isRecommended: true,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        providerNotifier.toggleSamagri(true);
                      },
                    ),

                  const SizedBox(height: 12),

                  if (puja.isWithoutSamagriAvailable)
                    _buildPackageCard(
                      title: "Basic (Pandit Only)",
                      subtitle: "You will arrange all the required puja samagri.",
                      price: puja.price.withoutSamagriTotal,
                      isSelected: !providerState.isSamagriIncluded,
                      isRecommended: false,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        providerNotifier.toggleSamagri(false);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📅 3. DATE & TIME SELECTION
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Select Date", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.3)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 85,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      separatorBuilder: (_,__) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        DateTime date = DateTime.now().add(Duration(days: index + 1));
                        bool isSelected = providerState.selectedDate?.day == date.day;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            providerNotifier.setDate(date);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 68,
                            decoration: BoxDecoration(
                                color: isSelected ? Colors.deepOrange : Colors.white,
                                border: Border.all(color: isSelected ? Colors.deepOrange : Colors.grey.shade300, width: isSelected ? 2 : 1),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: isSelected ? [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : []
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat('MMM').format(date).toUpperCase(), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 22, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text(DateFormat('EEE').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey.shade800, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Select Time", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.3)),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 12, runSpacing: 12,
                      children: ["08:00 AM", "10:30 AM", "12:00 PM", "04:00 PM", "06:30 PM"].map((time) {
                        bool isSelected = providerState.selectedTime == time;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            providerNotifier.setTime(time);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                                color: isSelected ? Colors.deepOrange.withOpacity(0.1) : Colors.white,
                                border: Border.all(color: isSelected ? Colors.deepOrange : Colors.grey.shade300, width: isSelected ? 2 : 1),
                                borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(time, style: TextStyle(color: isSelected ? Colors.deepOrange : Colors.black87, fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📜 4. TRANSPARENT INVOICE / SPLIT BILL DETAILS
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Payment Summary", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.3)),
                  const SizedBox(height: 20),

                  _buildDetailedBillRow("Puja Ritual Fee", "To be paid to Pandit", basePrice),

                  if (providerState.isSamagriIncluded) ...[
                    const SizedBox(height: 12),
                    _buildDetailedBillRow("Puja Samagri Kit", "To be paid to Pandit", selectedSamagriPrice),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.grey.shade300, thickness: 1, height: 1),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Service Value", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                      Text("₹${payableToPandit.toInt()}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepOrange.withOpacity(0.2))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Booking Amount", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.deepOrange)),
                            Text("Platform & Security Fee", style: TextStyle(fontSize: 11, color: Colors.deepOrange.shade300, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text("₹${payableNow.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.deepOrange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 130),
          ],
        ),
      ),

      // 🚀 5. STICKY BOTTOM PAYMENT BAR
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text("100% Safe & Secure Payments", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("BOOKING AMOUNT", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        Text("₹${payableNow.toInt()}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.1)),
                        const SizedBox(height: 2),
                        Text("Pay ₹${payableToPandit.toInt()} to Pandit later", style: const TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 🌟 ULTRA PREMIUM MICRO-INTERACTIVE BUTTON
                  GestureDetector(
                    onTapDown: (_) {
                      if (!providerState.isProcessing) setState(() => _buttonScale = 0.95);
                    },
                    onTapUp: (_) {
                      if (!providerState.isProcessing) {
                        setState(() => _buttonScale = 1.0);
                        _executePayment();
                      }
                    },
                    onTapCancel: () {
                      if (!providerState.isProcessing) setState(() => _buttonScale = 1.0);
                    },
                    child: AnimatedScale(
                      scale: _buttonScale,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.fastOutSlowIn,
                        height: 56,
                        width: providerState.isProcessing ? 56 : MediaQuery.of(context).size.width * 0.45,
                        decoration: BoxDecoration(
                            color: providerState.isProcessing ? Colors.deepOrange.shade400 : Colors.deepOrange,
                            borderRadius: BorderRadius.circular(providerState.isProcessing ? 28 : 16),
                            boxShadow: providerState.isProcessing ? [] : [
                              BoxShadow(color: Colors.deepOrange.withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 6))
                            ]
                        ),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: providerState.isProcessing
                              ? const SizedBox(
                            key: ValueKey("loader"),
                            height: 24, width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3, strokeCap: StrokeCap.round),
                          )
                              : const Text(
                            "Pay & Confirm",
                            key: ValueKey("text"),
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildPackageCard({
    required String title,
    required String subtitle,
    required double price,
    required bool isSelected,
    required bool isRecommended,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.deepOrange : Colors.grey.shade200,
              width: isSelected ? 2 : 1
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 22, width: 22,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? Colors.deepOrange : Colors.grey.shade400, width: isSelected ? 6 : 2),
                  color: Colors.white
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRecommended)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                      child: const Text("RECOMMENDED", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text("₹${price.toInt()}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? Colors.deepOrange : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBillRow(String title, String subtitle, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        Text("₹${amount.toInt()}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
      ],
    );
  }
}