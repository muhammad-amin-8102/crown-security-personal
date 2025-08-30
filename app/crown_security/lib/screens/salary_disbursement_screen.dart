import 'package:crown_security/core/api.dart';
import 'package:flutter/material.dart';

class SalaryDisbursementScreen extends StatefulWidget {
  const SalaryDisbursementScreen({super.key});

  @override
  State<SalaryDisbursementScreen> createState() =>
      _SalaryDisbursementScreenState();
}

class _SalaryDisbursementScreenState extends State<SalaryDisbursementScreen> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSalaryDisbursements();
  }

  Future<void> _loadSalaryDisbursements() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
      final response = await Api.dio.get('/payroll/status', queryParameters: {'siteId': siteId});
      setState(() {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          _status = data;
        } else if (data is List && data.isNotEmpty) {
          _status = Map<String, dynamic>.from(data.first);
        } else {
          _status = null;
        }
      });
    } catch (e) {
      _error = 'Failed to load salary disbursements.';
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
        title: const Text('Salary Disbursement'),
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
    if (_status == null) {
      return const Center(child: Text('No disbursement data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadSalaryDisbursements,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                Icons.payment,
                color: (_status!['status']?.toString().toLowerCase() == 'paid')
                    ? Colors.green
                    : Colors.orange,
              ),
              title: Text(
                (_status!['month'] ?? 'Current Cycle').toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Status: ${_status!['status'] ?? 'N/A'}'),
              trailing: Text('Date: ${_status!['date_paid'] ?? _status!['date'] ?? '-'}'),
            ),
          ),
        ],
      ),
    );
  }
}
