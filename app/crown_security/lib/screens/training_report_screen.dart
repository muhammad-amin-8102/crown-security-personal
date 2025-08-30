import 'package:crown_security/core/api.dart';
import 'package:flutter/material.dart';

class TrainingReportScreen extends StatefulWidget {
  const TrainingReportScreen({super.key});

  @override
  State<TrainingReportScreen> createState() => _TrainingReportScreenState();
}

class _TrainingReportScreenState extends State<TrainingReportScreen> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrainingReport();
  }

  Future<void> _loadTrainingReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
      final response = await Api.dio.get('/training/latest', queryParameters: {'siteId': siteId});
      final tr = response.data;
      setState(() {
        _report = (tr is List && tr.isNotEmpty) ? tr[0] : tr;
      });
    } catch (e) {
      _error = 'Failed to load training report.';
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
        title: const Text('Training Report'),
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
    if (_report == null) {
      return const Center(child: Text('No report available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadTrainingReport,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.calendar_today, 'Date', _report!['date']),
                const Divider(height: 24),
                _buildDetailRow(Icons.person, 'Trainer', _report!['trainer']),
                const Divider(height: 24),
                _buildDetailRow(Icons.group, 'Attendance', _report!['attendance'].toString()),
                const Divider(height: 24),
                Text(
                  'Topics Covered:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _report!['topics_covered'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.8)),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
