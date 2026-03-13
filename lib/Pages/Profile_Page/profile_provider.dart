// lib/providers/profile_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubhnow_user/Pages/Profile_Page/profile_model.dart';
import 'package:shubhnow_user/Pages/Profile_Page/profile_service.dart';
import 'package:flutter/material.dart'; // Naya import cache clear karne ke liye
// --- SERVICE PROVIDER ---
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// --- STATE CONTROLLER PROVIDER ---
final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<ProfileModel>>((ref) {
  return ProfileController(ref.read(profileServiceProvider));
});

class ProfileController extends StateNotifier<AsyncValue<ProfileModel>> {
  final ProfileService _profileService;

  ProfileController(this._profileService) : super(const AsyncValue.loading()) {
    fetchUserProfile(); // App khulte hi profile fetch hogi
  }

  // ==========================================
  // 1. FETCH PROFILE (Single Source of Truth)
  // ==========================================
  Future<void> fetchUserProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _profileService.fetchProfile();
      if (mounted) state = AsyncValue.data(profile);
    } catch (e, stack) {
      if (mounted) state = AsyncValue.error(e.toString(), stack);
    }
  }

  // ==========================================
  // 2. UPDATE PROFILE (Handles Avatar, Name, Email)
  // ==========================================
// ==========================================
  // 2. UPDATE PROFILE
  // ==========================================
// ==========================================
  // 2. UPDATE PROFILE & CLEAR CACHE (INDUSTRY FIX)
  // ==========================================
  Future<void> updateProfile({String? fullName, String? email, File? imageFile}) async {
    state = const AsyncValue.loading();
    try {
      // 🚀 THE FIX: Directly update state with returned data
      final updatedUser = await _profileService.updateProfile(
          fullName: fullName,
          email: email,
          imageFile: imageFile
      );

      // State ko instantly naye data se update karo
      if (mounted) state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      // Error aane par purana data fetch kar lo
      await fetchUserProfile();
      state = AsyncValue.error(e.toString(), stack);
    }
  }  // 3. ADDRESS MANAGEMENT
  // ==========================================

  Future<void> addAddress(Map<String, dynamic> addressData) async {
    state = const AsyncValue.loading();
    try {
      await _profileService.addAddress(addressData);
      await fetchUserProfile(); // Backend ne array update kiya, humne fetch kar liya!
    } catch (e) {
      await fetchUserProfile();
      print("Add Address Error: $e");
      rethrow;
    }
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    state = const AsyncValue.loading();
    try {
      await _profileService.updateAddress(addressId, addressData);
      await fetchUserProfile();
    } catch (e) {
      await fetchUserProfile();
      print("Update Address Error: $e");
      rethrow;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    state = const AsyncValue.loading();
    try {
      await _profileService.deleteAddress(addressId);
      await fetchUserProfile();
    } catch (e) {
      await fetchUserProfile();
      print("Delete Address Error: $e");
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    state = const AsyncValue.loading();
    try {
      await _profileService.setDefaultAddress(addressId);
      await fetchUserProfile();
    } catch (e) {
      await fetchUserProfile();
      print("Set Default Address Error: $e");
      rethrow;
    }
  }
}