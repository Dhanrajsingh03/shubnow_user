import 'package:dio/dio.dart';
import '../../core/dio_client.dart'; // 🔥 Dhyan rakhna, apna DioClient ka sahi path daalna
import 'puja_model.dart';

class PujaService {
  // 🌐 Dio instance for network calls
  final Dio _dio = DioClient.instance;

  // 📍 Backend API Endpoints
  // Note: Agar tumhara express app '/pujas' par mounted hai, toh path ye hoga:
  static const String _getAllPujasEndpoint = '/pujas/user/all';
  static const String _getPujaByIdEndpoint = '/pujas/user/';

  // ==========================================
  // 1. FETCH ALL PUJAS (Marketplace Catalog)
  // ==========================================
  Future<List<PujaModel>> fetchAllPujas() async {
    try {
      // GET request to /pujas/user/all
      final response = await _dio.get(_getAllPujasEndpoint);

      // BackendApiResponse wrap karta hai data ko 'data' key ke andar
      final List data = response.data['data'];

      // JSON array ko List of PujaModel me map kar rahe hain
      return data.map((json) => PujaModel.fromJson(json)).toList();

    } on DioException catch (e) {
      // Backend se bheja gaya custom error message dikhayenge
      throw Exception(e.response?.data['message'] ?? 'Failed to load Pujas. Please try again.');
    } catch (e) {
      // Dart ka koi fallback error
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // ==========================================
  // 2. FETCH SINGLE PUJA DETAILS
  // ==========================================
  // Jab user kisi puja card par click karega, tab ye kaam aayega
  Future<PujaModel> fetchPujaById(String id) async {
    try {
      // GET request to /pujas/user/:id
      final response = await _dio.get('$_getPujaByIdEndpoint$id');

      // Backend returns a single aggregated object in 'data'
      return PujaModel.fromJson(response.data['data']);

    } on DioException catch (e) {
      // Handle "Currently, no Pandit Ji is available..." error
      throw Exception(e.response?.data['message'] ?? 'Failed to load Puja details.');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}