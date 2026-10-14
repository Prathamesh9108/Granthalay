import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService extends ChangeNotifier {
  String _baseUrl = AppConstants.defaultApiBaseUrl;
  bool _isDemoMode = false; // Real-time live database mode

  String get baseUrl => _baseUrl;
  bool get isDemoMode => _isDemoMode;

  ApiService() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(AppConstants.keyApiBaseUrl);
      final savedDemoMode = prefs.getBool(AppConstants.keyIsDemoMode);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        // Auto-migrate stale local/emulator/localhost URLs to current cloud default
        if (savedUrl.contains('192.168.1.16') ||
            savedUrl.contains('10.0.2.2') ||
            savedUrl.contains('192.168.1.46') ||
            savedUrl.contains('localhost') ||
            savedUrl.contains('127.0.0.1')) {
          _baseUrl = AppConstants.defaultApiBaseUrl;
          await prefs.setString(AppConstants.keyApiBaseUrl, _baseUrl);
        } else {
          _baseUrl = savedUrl;
        }
      }
      // Always default to live database mode unless explicitly toggled
      if (savedDemoMode != null) {
        _isDemoMode = savedDemoMode;
      } else {
        _isDemoMode = false;
        await prefs.setBool(AppConstants.keyIsDemoMode, false);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyApiBaseUrl, _baseUrl);
    } catch (_) {}
  }

  Future<void> setDemoMode(bool isDemo) async {
    _isDemoMode = isDemo;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsDemoMode, isDemo);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> testConnection() async {
    try {
      final res = await get('/dashboard/statistics');
      if (res is Map<String, dynamic>) {
        final totalBooks = res['totalBooks'] ?? 0;
        final totalMembers = res['totalMembers'] ?? 0;
        return {
          'success': true,
          'message': 'Connected to MySQL! ($totalBooks books, $totalMembers members)',
          'stats': res,
        };
      }
      return {'success': true, 'message': 'Connected to server successfully!'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters, String? overrideBase]) {
    var cleanBase = (overrideBase ?? _baseUrl).trim();
    if (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }
    var cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath').replace(queryParameters: queryParameters);
  }

  Future<dynamic> _executeWithFallback(Future<http.Response> Function(String baseUrl) requestFn) async {
    try {
      final response = await requestFn(_baseUrl).timeout(const Duration(milliseconds: 2500));
      return _processResponse(response);
    } catch (e) {
      // If primary URL failed, try alternative URL (localhost <-> wifi IP)
      final fallbackUrl = _baseUrl.contains('localhost')
          ? AppConstants.defaultWifiUrl
          : AppConstants.defaultLocalhostUrl;
      if (_baseUrl != fallbackUrl) {
        try {
          final fallbackResponse = await requestFn(fallbackUrl).timeout(const Duration(milliseconds: 2500));
          _baseUrl = fallbackUrl;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.keyApiBaseUrl, _baseUrl);
          notifyListeners();
          return _processResponse(fallbackResponse);
        } catch (_) {}
      }
      if (e is ApiException) rethrow;
      throw ApiException('Cannot reach Spring Boot server at $_baseUrl: $e');
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    return _executeWithFallback((base) {
      final uri = _buildUri(path, queryParams, base);
      return http.get(uri, headers: _headers);
    });
  }

  Future<dynamic> post(String path, dynamic body) async {
    return _executeWithFallback((base) {
      final uri = _buildUri(path, null, base);
      return http.post(uri, headers: _headers, body: jsonEncode(body));
    });
  }

  Future<dynamic> put(String path, dynamic body) async {
    return _executeWithFallback((base) {
      final uri = _buildUri(path, null, base);
      return http.put(uri, headers: _headers, body: jsonEncode(body));
    });
  }

  Future<dynamic> delete(String path) async {
    return _executeWithFallback((base) {
      final uri = _buildUri(path, null, base);
      return http.delete(uri, headers: _headers);
    });
  }

  Future<dynamic> postMultipart(
    String path,
    String filePath, {
    String fieldName = 'file',
  }) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      final streamedResponse = await request.send().timeout(const Duration(minutes: 3));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach Spring Boot server at $_baseUrl.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Upload error: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      String errorMessage = 'Server returned status ${response.statusCode}';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {}
      throw ApiException(errorMessage, response.statusCode);
    }
  }
}
