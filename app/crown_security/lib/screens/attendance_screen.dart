import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic>? _attendance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
    try {
      final sitesResp = await dio.get(
        '/sites',
        queryParameters: {'client_id': userId},
      );
      final sites = sitesResp.data as List?;
      if (sites == null || sites.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No site assigned.';
        });
        return;
      }
      final siteId = sites.first['id'];
      final attResp = await dio.get(
        '/attendance',
        queryParameters: {'siteId': siteId},
      );
      setState(() {
        _attendance = attResp.data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load attendance.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _attendance == null
              ? const Center(child: Text('No data'))
              : ListView.builder(
                itemCount: _attendance!.length,
                itemBuilder: (context, i) {
                  final att = _attendance![i];
                  return Card(
                    child: ListTile(
                      title: Text('Date: ${att['date']}'),
                      subtitle: Text(
                        'Present: ${att['status']}, Guard: ${att['guard_id']}',
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
