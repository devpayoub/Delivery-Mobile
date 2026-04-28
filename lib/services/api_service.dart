import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery.dart';
import '../models/driver.dart';
import '../models/product_type.dart';
import '../models/employer.dart';
import '../models/log_entry.dart';

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
        final user = response.data['user'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_id', user['id'] ?? '');
        await prefs.setString('user_role', user['role'] ?? 'driver');
        await prefs.setString('user_name', user['name'] ?? 'User');
        
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

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
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

  Future<bool> createDelivery(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      debugPrint('Creating delivery with data: $data');
      final response = await _dio.post(
        '/deliveries',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint('Create delivery response: ${response.statusCode} - ${response.data}');
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Create delivery error: $e');
      return false;
    }
  }

  Future<bool> updateDelivery(String id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
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

  Future<bool> deleteDelivery(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.delete(
        '/deliveries/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDeliveryStatus(String id, String status, {String? reason}) async {
    return await updateDelivery(id, {
      'status': status,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  // --- Drivers, Cities, Product Types ---
  Future<List<Driver>> getDrivers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.get(
        '/drivers',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Driver.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load drivers');
    }
  }

  Future<List<City>> getCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/cities',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => City.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load cities');
    }
  }

  Future<List<ProductType>> getProductTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/product-types',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => ProductType.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load product types');
    }
  }

  Future<bool> assignDriverToCity(String driverId, String cityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.put(
        '/drivers/$driverId',
        data: {'city_id': cityId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Employers (Owner only) ---
  Future<List<Employer>> getEmployers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.get(
        '/employers',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Employer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load employers');
    }
  }

  Future<Employer?> getEmployerById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.get(
        '/employers/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return Employer.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createEmployer(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.post(
        '/employers',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEmployer(String id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.put(
        '/employers/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEmployer(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.delete(
        '/employers/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Deliveries filtered by employer_id ---
  Future<List<Delivery>> getEmployerDeliveries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getString('user_id');
      
      if (token == null || userId == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/deliveries',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        final allDeliveries = data.map((json) => Delivery.fromJson(json)).toList();
        return allDeliveries.where((d) => d.employerId == userId).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load deliveries');
    }
  }

  // --- Logs ---
  Future<List<LogEntry>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/logs',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => LogEntry.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load logs');
    }
  }

  // --- Cities CRUD (Owner) ---
  Future<bool> createCity(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.post(
        '/cities',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCity(String id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.put(
        '/cities/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCity(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.delete(
        '/cities/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Product Types CRUD (Owner) ---
  Future<bool> createProductType(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.post(
        '/product-types',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProductType(String id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.put(
        '/product-types/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProductType(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.delete(
        '/product-types/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Drivers CRUD (Owner) ---
  Future<bool> createDriver(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.post(
        '/drivers',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDriver(String id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.put(
        '/drivers/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDriver(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await _dio.delete(
        '/drivers/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final apiService = ApiService();
