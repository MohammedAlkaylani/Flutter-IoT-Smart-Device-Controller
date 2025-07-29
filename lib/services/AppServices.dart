import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _baseUrl = 'https://api.yourdomain.com/v1';

  File? _profilePicture;
  int? _userId;
  File? get profilePicture => _profilePicture;

  // User Data Management
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    return userString != null ? jsonDecode(userString) : null;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }

  // Authentication Methods
  static Future<Map<String, dynamic>> loginUser(String usernameOrEmail) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': usernameOrEmail}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String passwordHash,
    required String salt,
    String? fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password_hash': passwordHash,
          'salt': salt,
          'full_name': fullName,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Password Utilities
  static String generateSalt([int length = 32]) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(saltBytes);
  }

  static String hashPassword(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String storedHash, String salt, String inputPassword) {
    return hashPassword(inputPassword, salt) == storedHash;
  }

  static Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Profile Picture Management
  Future<void> initializeProfileService(int userId) async {
    _userId = userId;
    await _loadProfilePicture();
    notifyListeners();
  }

  static Future<Map<String, dynamic>> uploadProfilePicture({
    required int userId,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/user/upload-profile-picture'),
      );
      request.fields['user_id'] = userId.toString();
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      var response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _loadProfilePicture() async {
    if (_userId == null) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/profile_pic_$_userId.jpg');
      
      if (await file.exists()) {
        _profilePicture = file;
        return;
      }
      await _downloadProfilePicture();
    } catch (e) {
      debugPrint('Error loading profile picture: $e');
    }
  }

  Future<void> _downloadProfilePicture({bool forceRefresh = false}) async {
    if (_userId == null) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/profile_pic_$_userId.jpg');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user/profile-picture/$_userId'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _profilePicture = file;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error downloading profile picture: $e');
    }
  }

  // Device Management
  static Future<List<Map<String, dynamic>>> getUserDevices(int userId) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '$_baseUrl/user/devices/$userId',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] && data['devices'] != null) {
          return List<Map<String, dynamic>>.from(data['devices']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      return [];
    }
  }

  static Future<bool> addDevice({
    required String deviceId,
    required int userId,
    required String deviceName,
    required String deviceType,
    required String deviceAddress,
  }) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '$_baseUrl/user/devices',
        data: {
          'device_id': deviceId,
          'user_id': userId,
          'device_name': deviceName,
          'device_type': deviceType,
          'device_address': deviceAddress,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding device: $e');
      return false;
    }
  }
}