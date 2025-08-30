import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

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
      final spendResp = await dio.get(
        '/spend',
        queryParameters: {'siteId': siteId},
      );
      final spendList = spendResp.data as List?;
      _total =
          spendList?.fold(
            0,
            (sum, item) =>
                (sum ?? 0) + (double.tryParse(item['amount'].toString()) ?? 0),
          ) ??
          0;
      setState(() {
        _spend = spendList;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load spend.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spend')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _spend == null
              ? const Center(child: Text('No data'))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total Spend: ₹$_total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _spend!.length,
                      itemBuilder: (context, i) {
                        final spend = _spend![i];
                        return Card(
                          child: ListTile(
                            title: Text('Date: ${spend['date']}'),
                            subtitle: Text(
                              'Amount: ₹${spend['amount']}\n${spend['description']}',
                            ),
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
