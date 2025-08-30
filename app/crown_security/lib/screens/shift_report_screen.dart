import 'package:crown_security/core/api.dart';
import 'package:flutter/material.dart';

class ShiftReportScreen extends StatefulWidget {
  const ShiftReportScreen({super.key});

  @override
  State<ShiftReportScreen> createState() => _ShiftReportScreenState();
}

class _ShiftReportScreenState extends State<ShiftReportScreen> {
  List<dynamic>? _shiftData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShiftReport();
  }

  Future<void> _loadShiftReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
      final response = await Api.dio.get('/shifts', queryParameters: {'siteId': siteId});
      setState(() {
        _shiftData = response.data;
      });
    } catch (e) {
      _error = 'Failed to load shift report.';
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
      appBar: AppBar(
        title: const Text('Shift-wise Report'),
      ),
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
    if (_shiftData == null || _shiftData!.isEmpty) {
      return const Center(child: Text('No shift data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadShiftReport,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shiftData!.length,
        itemBuilder: (context, index) {
          final shift = _shiftData![index];
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.schedule,
                  color: Theme.of(context).primaryColor),
              title: Text(shift['shift'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Time: ${shift['time']}'),
              trailing: Text(
                'Guards: ${shift['guards']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        },
      ),
    );
  }
}
