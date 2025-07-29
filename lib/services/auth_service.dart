import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Use your production API endpoint here
  static const String _baseUrl = 'https://api.yourdomain.com/v1/auth';
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  /// Saves user data to persistent storage
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  /// Retrieves saved user data from persistent storage
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    return userString != null ? jsonDecode(userString) : null;
  }

  /// Clears all user authentication data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  /// Checks if a user is currently logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }

  /// Fetches the user's profile picture URL from the server
  static Future<String?> getProfilePicture(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile/picture/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['url']; // Updated response structure
        }
      }
      return null;
    } catch (e) {
      // Consider using a proper logging solution in production
      debugPrint('Error fetching profile picture: $e');
      return null;
    }
  }

  // Additional recommended methods:

  /// Saves authentication token
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieves authentication token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Validates the current authentication status with server
  static Future<bool> validateSession() async {
    try {
      final token = await getAuthToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$_baseUrl/validate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Session validation error: $e');
      return false;
    }
  }
}