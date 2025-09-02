import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class Api {
  static final _storage = const FlutterSecureStorage();
  
  // API Base URL configuration
  static String get baseUrl {
    if (kIsWeb) {
      // For web builds, use relative URL or current domain
      if (kDebugMode) {
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000/api/v1',
        );
      } else {
        // Production web build - use same domain
        return '${Uri.base.origin}/api/v1';
      }
    } else {
      // Mobile builds - point to production server
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://crown-security-personal.onrender.com/api/v1',
      );
    }
  }
  
  static final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, redirect to login
            await _storage.delete(key: 'access_token');
            await _storage.delete(key: 'refresh_token');
          }
          handler.next(error);
        },
      ),
    );

  static Future<bool> login(String email, String password) async {
    try {
      print('🔐 Login attempt for: $email');
      print('🌐 API Base URL: $baseUrl');
      print('📤 Request data: ${jsonEncode({'email': email, 'password': password})}');
      
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      
      print('✅ Login response status: ${response.statusCode}');
      print('📥 Login response data: ${jsonEncode(response.data)}');
      
      await _storage.write(
        key: 'access_token',
        value: response.data['access_token'],
      );
      await _storage.write(
        key: 'refresh_token',
        value: response.data['refresh_token'],
      );
      // Save user id for dashboard site lookup
      final user = response.data['user'];
      if (user != null && user['id'] != null) {
        await _storage.write(key: 'user_id', value: user['id']);
        // Store full user JSON
        try { await _storage.write(key: 'user_profile', value: jsonEncode(user)); } catch (_) {}
        // Persist role for client-side gating (supports role or roles[])
        try {
          final dynamic rolesField = user['roles'];
          String? role = user['role']?.toString();
          if (role == null && rolesField is List && rolesField.isNotEmpty) {
            role = rolesField.first.toString();
          }
          if (role != null) {
            await _storage.write(key: 'role', value: role);
            print('👤 User role saved: $role');
          }
        } catch (_) {}
      }
      return true;
    } catch (e) {
      print('❌ Login error: $e');
      if (e is DioException) {
        print('🔍 Error type: ${e.type}');
        print('📊 Status code: ${e.response?.statusCode}');
        print('📄 Error response: ${e.response?.data}');
        print('🌐 Request URL: ${e.requestOptions.uri}');
      }
      return false;
    }
  }

  static FlutterSecureStorage get storage => _storage;

  static Future<Map<String, dynamic>?> fetchDashboard(
    String siteId,
    String from,
    String to,
  ) async {
    try {
      final response = await dio.get(
        '/reports/summary',
        queryParameters: {'siteId': siteId, 'from': from, 'to': to},
      );
      final data = response.data as Map<String, dynamic>;

      // Set safe default values for all expected fields
      data['latestNightRound'] = null;
      data['latestTraining'] = null;
      data['complaintsCount'] = 0;
      data['monthlyNPS'] = null;

      // Re-enable API calls one by one
  try {
        final nightRoundRes = await dio.get('/night-rounds/latest', queryParameters: {'siteId': siteId});
        data['latestNightRound'] = nightRoundRes.data;
      } catch (e) {
        // Keep default value if API fails
      }

      try {
        final trainingRes = await dio.get('/training/latest', queryParameters: {'siteId': siteId});
        final tr = trainingRes.data;
        // Normalize in case API returns a list instead of an object
        data['latestTraining'] = (tr is List && tr.isNotEmpty) ? tr[0] : tr;
      } catch (e) {
        // Keep default value if API fails
      }

      try {
        final complaintsRes = await dio.get('/complaints', queryParameters: {'siteId': siteId, 'limit': 5});
        data['complaints'] = complaintsRes.data;
      } catch (e) {
        // Keep default value if API fails
      }

      try {
        final ratingRes = await dio.get('/ratings', queryParameters: {'siteId': siteId});
        final rr = ratingRes.data;
        if (rr is List) {
          if (rr.isEmpty) {
            data['latestRating'] = null;
          } else {
            final first = rr[0] as Map<String, dynamic>;
            data['latestRating'] = {
              ...first,
              'rating': first['rating'] ?? first['rating_value'],
              'npsScore': first['npsScore'] ?? first['nps_score'],
            };
          }
        } else if (rr is Map<String, dynamic>) {
          data['latestRating'] = {
            ...rr,
            'rating': rr['rating'] ?? rr['rating_value'],
            'npsScore': rr['npsScore'] ?? rr['nps_score'],
          };
        } else {
          data['latestRating'] = null;
        }
      } catch (e) {
        // Keep default value if API fails
      }

  try {
        final soaRes = await dio.get('/billing/soa', queryParameters: {'siteId': siteId});
        data['soa'] = soaRes.data;
      } catch (e) {
        // Keep default value if API fails
      }

  try {
        final payrollRes = await dio.get('/payroll/status', queryParameters: {'siteId': siteId});
        data['payroll'] = payrollRes.data;
      } catch (e) {
        // Keep default value if API fails
      }

      try {
        final shiftReportRes = await dio.get('/shifts/latest', queryParameters: {'siteId': siteId});
        data['latestShiftReport'] = shiftReportRes.data;
      } catch (e) {
        // Keep default value if API fails
      }

      // Fetch site details for header card
      try {
        final siteRes = await dio.get('/sites/$siteId');
        data['site'] = siteRes.data;
      } catch (e) {
        // ignore
      }

      // Compute attendance counts for the same range used by the dashboard
      try {
        final attRes = await dio.get('/attendance', queryParameters: {
          'siteId': siteId,
          'from': from,
          'to': to,
        });
        List list;
        final res = attRes.data;
        if (res is List) {
          list = res;
        } else if (res is Map && res['items'] is List) {
          list = (res['items'] as List);
        } else {
          list = const [];
        }
        final upper = (String? s) => (s ?? '').toUpperCase();
        final present = list.where((e) => upper(e['status']) == 'PRESENT').length;
        final absent = list.where((e) => upper(e['status']) == 'ABSENT').length;
        data['tillDateAttendance'] = {
          'PRESENT': present,
          'ABSENT': absent,
          'TOTAL': list.length,
        };
      } catch (e) {
        // ignore
      }

  // Attendance and spend are already included in /reports/summary as
  // tillDateAttendance (object) and tillDateSpend (number). Avoid overriding.

      return data;
    } catch (e) {
      return null;
    }
  }
}
