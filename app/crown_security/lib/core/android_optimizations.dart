import 'package:flutter/services.dart';

class AndroidOptimizations {
  static const MethodChannel _channel = MethodChannel('com.crowntech.security/battery');

  static Future<void> requestBatteryOptimizationDisable() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimizationDisable');
    } catch (e) {
      print('Failed to request battery optimization disable: $e');
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      print('Failed to open app settings: $e');
    }
  }
}
