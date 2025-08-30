import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  static final _storage = const FlutterSecureStorage();
  static final dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'API_BASE',
          defaultValue: 'http://localhost:8080/api/v1',
        ),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );

  static Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
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
      }
      return true;
    } catch (e) {
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
      final data = response.data;

      // Fetch latest night round
      final nightRoundRes = await dio.get('/night-rounds/latest', queryParameters: {'siteId': siteId});
      data['latestNightRound'] = nightRoundRes.data;

      // Fetch latest training
      final trainingRes = await dio.get('/trainings/latest', queryParameters: {'siteId': siteId});
      if (trainingRes.data != null) {
        // Ensure the data for the dashboard is structured correctly
        data['latestTraining'] = {
          'topics_covered': trainingRes.data['topics_covered']?.toString(),
          // Pass the full object for the details screen
          'full_report': trainingRes.data 
        };
      } else {
        data['latestTraining'] = null;
      }

      // Fetch complaints count
      final complaintsRes = await dio.get('/complaints', queryParameters: {'site_id': siteId});
      data['complaintsCount'] = (complaintsRes.data as List).where((c) => c['status'] == 'OPEN').length;

      // Fetch latest rating/nps
      final ratingRes = await dio.get('/ratings', queryParameters: {'site_id': siteId});
      if((ratingRes.data as List).isNotEmpty) {
        data['monthlyNPS'] = (ratingRes.data as List).first['nps_score'];
      }


      return data;
    } catch (e) {
      return null;
    }
  }
}
