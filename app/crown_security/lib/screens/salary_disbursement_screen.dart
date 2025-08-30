import 'package:flutter/material.dart';

class SalaryDisbursementScreen extends StatefulWidget {
  const SalaryDisbursementScreen({super.key});

  @override
  State<SalaryDisbursementScreen> createState() =>
      _SalaryDisbursementScreenState();
}

class _SalaryDisbursementScreenState extends State<SalaryDisbursementScreen> {
  List<dynamic>? _disbursements;
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
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      _disbursements = [
        {'month': 'August 2025', 'status': 'Paid', 'date': '2025-08-05'},
        {'month': 'July 2025', 'status': 'Paid', 'date': '2025-07-05'},
        {'month': 'June 2025', 'status': 'Paid', 'date': '2025-06-05'},
      ];
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
    if (_disbursements == null || _disbursements!.isEmpty) {
      return const Center(child: Text('No disbursement data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadSalaryDisbursements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _disbursements!.length,
        itemBuilder: (context, index) {
          final disbursement = _disbursements![index];
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.payment,
                  color: disbursement['status'] == 'Paid'
                      ? Colors.green
                      : Colors.orange),
              title: Text(disbursement['month'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: ${disbursement['status']}'),
              trailing: Text('Date: ${disbursement['date']}'),
            ),
          );
        },
      ),
    );
  }
}
