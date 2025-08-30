import 'package:crown_security/core/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendScreen extends StatefulWidget {
  const SpendScreen({super.key});

  @override
  State<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends State<SpendScreen> {
  List<dynamic>? _spend;
  bool _loading = true;
  String? _error;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadSpend();
  }

  Future<void> _loadSpend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
      final response = await Api.dio.get('/spend/all', queryParameters: {'siteId': siteId});
      final spendList = response.data as List?;
    _total = (spendList ?? const [])
      .fold<double>(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));
      setState(() {
        _spend = spendList;
      });
    } catch (e) {
      _error = 'Failed to load spend data.';
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
      appBar: AppBar(title: const Text('Spend')),
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
    if (_spend == null || _spend!.isEmpty) {
      return const Center(child: Text('No spend data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadSpend,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Spend: ',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                          .format(_total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _spend!.length,
              itemBuilder: (context, i) {
                final item = _spend![i];
                final date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: Text(item['description']),
                    subtitle: Text(
                      NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                          .format(double.tryParse(item['amount'].toString()) ?? 0),
                    ),
                    trailing: Text(DateFormat.yMMMd().format(date)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
