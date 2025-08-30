import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AuthService {
  static final Dio dio = Dio(
    BaseOptions(baseUrl: 'http://localhost:8080/api/v1'),
  );

  Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response.data['access_token']);
      await prefs.setString('role', response.data['user']['role']);
      await prefs.setString('user_id', response.data['user']['id']);
      return response.data['user']['role'] == 'CLIENT';
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}
