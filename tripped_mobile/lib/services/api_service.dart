import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 'localhost' for Web, '10.0.2.2' for Android Emulator
  static const String baseUrl = 'http://localhost:5000/api';

  // --- REGISTER METHOD ---
  static Future<void> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        // Changed /users/register to /auth/register to match your server.js
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to register');
      }
    } catch (e) {
      throw Exception('Connection Error: Make sure your backend is running.');
    }
  }

  // --- LOGIN METHOD ---
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        // Changed /users/login to /auth/login to match your server.js
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      throw Exception('Connection Error: Could not reach the server.');
    }
  }
}
