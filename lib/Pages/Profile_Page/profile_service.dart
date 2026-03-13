// lib/services/profile_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shubhnow_user/Pages/Profile_Page/profile_model.dart';
// 🔥 TODO: Apne api_constants.dart aur dio_client ka sahi path daal lena
import '../../core/dio_client.dart';

class ProfileService {
  final Dio _dio = DioClient.instance;

  // 📍 EXACT ENDPOINTS FROM YOUR NODE.JS BACKEND
  static const String _profileEndpoint = '/users/me';
  static const String _updateProfileEndpoint = '/users/update-profile';
  static const String _addressEndpoint = '/users/address';

  // ==========================================
  // 1. FETCH PROFILE
  // ==========================================
  Future<ProfileModel> fetchProfile() async {
    try {
      final response = await _dio.get(_profileEndpoint);
      return ProfileModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load profile.');
    }
  }

  // ==========================================
  // 2. UPDATE PROFILE (Image + Text via FormData)
  // ==========================================
// ==========================================
  // 2. UPDATE PROFILE (Returns Updated Data directly)
  // ==========================================
  Future<ProfileModel> updateProfile({String? fullName, String? email, File? imageFile}) async {
    try {
      FormData formData = FormData();
      if (fullName != null) formData.fields.add(MapEntry('fullName', fullName));
      if (email != null) formData.fields.add(MapEntry('email', email));

      if (imageFile != null) {
        formData.files.add(MapEntry(
            "avatar",
            await MultipartFile.fromFile(imageFile.path)
        ));
      }

      // 🚀 THE FIX: Capture the response data
      final response = await _dio.patch('/users/update-profile', data: formData);

      // Backend returns { data: userObject }, parse it directly
      return ProfileModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Update failed');
    }
  }  // 3. ADDRESS CRUD OPERATIONS
  // ==========================================

  // ADD NEW ADDRESS
  Future<void> addAddress(Map<String, dynamic> addressData) async {
    try {
      await _dio.post(_addressEndpoint, data: addressData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to add address.');
    }
  }

  // UPDATE EXISTING ADDRESS
  Future<void> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    try {
      await _dio.patch('$_addressEndpoint/$addressId', data: addressData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update address.');
    }
  }

  // DELETE ADDRESS
  Future<void> deleteAddress(String addressId) async {
    try {
      await _dio.delete('$_addressEndpoint/$addressId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete address.');
    }
  }

  // SET DEFAULT ADDRESS
  Future<void> setDefaultAddress(String addressId) async {
    try {
      await _dio.patch('$_addressEndpoint/default/$addressId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to set default address.');
    }
  }
}