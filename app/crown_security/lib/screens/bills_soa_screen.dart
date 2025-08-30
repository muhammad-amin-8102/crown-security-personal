import 'package:crown_security/core/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillsSoaScreen extends StatefulWidget {
  const BillsSoaScreen({super.key});

  @override
  State<BillsSoaScreen> createState() => _BillsSoaScreenState();
}

class _BillsSoaScreenState extends State<BillsSoaScreen> {
  List<dynamic>? _bills;
  num? _outstanding;
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
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
      final response = await Api.dio.get('/billing/soa', queryParameters: {'siteId': siteId});
      final data = response.data;
      setState(() {
        if (data is Map) {
          _bills = (data['items'] as List?) ?? <dynamic>[];
          _outstanding = data['outstanding'] as num?;
        } else if (data is List) {
          _bills = data;
          _outstanding = null;
        } else {
          _bills = <dynamic>[];
          _outstanding = null;
        }
      });
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_outstanding != null)
            Card(
              color: Colors.red.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.red),
                title: const Text('Outstanding Total'),
                trailing: Text('₹${NumberFormat('#,##0.00').format(_outstanding)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ),
          const SizedBox(height: 8),
          ..._bills!.map((bill) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  Icons.receipt,
                  color: (bill['status'] ?? '').toString().toLowerCase() == 'paid' ? Colors.green : Colors.red,
                ),
                title: Text('Bill #${bill['id'] ?? ''} - ${bill['month'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Amount: ₹${bill['amount'] ?? ''} - Due: ${bill['dueDate'] ?? bill['due_date'] ?? ''}'),
                trailing: Text(
                  bill['status']?.toString() ?? 'Pending',
                  style: TextStyle(
                    color: (bill['status'] ?? '').toString().toLowerCase() == 'paid' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
