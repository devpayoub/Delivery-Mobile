import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/delivery.dart';

class ApiService {
  // Using dotenv to load the API URL
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3000/api'; 
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // --- Auth ---
  Future<bool> login(String identifier, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        // Ensure user is a driver
        if (response.data['user']['role'] != 'driver') {
          throw Exception('Only drivers can access this app');
        }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        return true;
      }
      return false;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? 'Login failed');
      }
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('jwt_token');
  }

  // --- Deliveries ---
  Future<List<Delivery>> getDeliveries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/deliveries',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Delivery.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load deliveries');
    }
  }

  Future<bool> updateDeliveryStatus(String id, String status, {String? reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      final data = {'status': status};
      if (reason != null && reason.trim().isNotEmpty) {
        data['reason'] = reason.trim();
      }

      final response = await _dio.put(
        '/deliveries/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Global instance for simple state management
final apiService = ApiService();
