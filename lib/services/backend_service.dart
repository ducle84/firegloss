import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Backend connection successful!',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Backend returned error: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: ${e.toString()}',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> createTestUser() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'email': 'test@firegloss.com',
              'name': 'Test User',
              'phone': '+1234567890',
              'password': 'testpass123',
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Test user created successfully!',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create user: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create user: ${e.toString()}',
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Users retrieved successfully!',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get users: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get users: ${e.toString()}',
        'data': null,
      };
    }
  }
}
