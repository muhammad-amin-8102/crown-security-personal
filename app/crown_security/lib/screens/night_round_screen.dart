import 'package:flutter/material.dart';
import '../core/api.dart';

class NightRoundScreen extends StatefulWidget {
  const NightRoundScreen({super.key});

  @override
  State<NightRoundScreen> createState() => _NightRoundScreenState();
}

class _NightRoundScreenState extends State<NightRoundScreen> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNightRoundReport();
  }

  Future<void> _loadNightRoundReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        _error = 'No site selected.';
        return;
      }
      final response = await Api.dio.get('/night-rounds/latest', queryParameters: {'siteId': siteId});
      _report = response.data;
    } catch (e) {
      _error = 'Failed to load night round report.';
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
        title: const Text('Night Round Report'),
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
      onRefresh: _loadNightRoundReport,
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
                _buildDetailRow(
                  Icons.calendar_today,
                  'Date',
                  (() {
                    final v = _report!['date'] ?? _report!['createdAt'];
                    if (v == null) return 'N/A';
                    DateTime? d;
                    if (v is String) d = DateTime.tryParse(v);
                    if (v is DateTime) d = v;
                    if (d == null) return v.toString();
                    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
                  })(),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  Icons.person,
                  'Officer',
                  (() {
                    final v = _report!['officer'] ?? _report!['officer_name'] ?? _report!['officerId'] ?? _report!['officer_id'];
                    return (v == null) ? 'N/A' : v.toString();
                  })(),
                ),
                const Divider(height: 24),
                Text(
                  'Findings:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text((_report!['findings'] ?? 'No findings').toString(), style: Theme.of(context).textTheme.bodyLarge),
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
          Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
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
