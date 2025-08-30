import 'package:flutter/material.dart';

class BillsSoaScreen extends StatefulWidget {
  const BillsSoaScreen({super.key});

  @override
  State<BillsSoaScreen> createState() => _BillsSoaScreenState();
}

class _BillsSoaScreenState extends State<BillsSoaScreen> {
  List<dynamic>? _bills;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      _bills = [
        {
          'id': 'B001',
          'month': 'August 2025',
          'amount': 50000.0,
          'dueDate': '2025-09-15',
          'status': 'Pending'
        },
        {
          'id': 'B002',
          'month': 'July 2025',
          'amount': 48000.0,
          'dueDate': '2025-08-15',
          'status': 'Paid'
        },
      ];
    } catch (e) {
      _error = 'Failed to load bills.';
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
        title: const Text('Outstanding Bills (SOA)'),
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
    if (_bills == null || _bills!.isEmpty) {
      return const Center(child: Text('No bills available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadBills,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bills!.length,
        itemBuilder: (context, index) {
          final bill = _bills![index];
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                Icons.receipt,
                color: bill['status'] == 'Paid' ? Colors.green : Colors.red,
              ),
              title: Text('Bill #${bill['id']} - ${bill['month']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Amount: ₹${bill['amount']} - Due: ${bill['dueDate']}'),
              trailing: Text(
                bill['status'],
                style: TextStyle(
                  color: bill['status'] == 'Paid' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
