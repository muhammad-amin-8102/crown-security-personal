import 'package:crown_security/core/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
      final response = await Api.dio.get('/attendance', queryParameters: {'siteId': siteId});
      setState(() {
        _attendance = response.data;
      });
    } catch (e) {
      _error = 'Failed to load attendance.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_attendance == null || _attendance!.isEmpty) {
      return const Center(child: Text('No attendance data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attendance!.length,
        itemBuilder: (context, index) {
          final att = _attendance![index];
          final date = DateTime.tryParse(att['date'] ?? '') ?? DateTime.now();
          final guardName = att['guard_name'] ?? att['guardName'] ?? att['guard'] ?? att['guard_id'];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                (att['status']?.toString().toUpperCase() == 'PRESENT') ? Icons.check_circle : Icons.cancel,
                color: (att['status']?.toString().toUpperCase() == 'PRESENT') ? Colors.green : Colors.red,
              ),
              title: Text('Guard: ${guardName.toString()}'),
              subtitle: Text('Status: ${att['status']}'),
              trailing: Text(DateFormat('dd-MM-yyyy').format(date)),
            ),
          );
        },
      ),
    );
  }
}
