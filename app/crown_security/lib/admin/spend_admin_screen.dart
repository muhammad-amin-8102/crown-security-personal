import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';

class SpendAdminScreen extends StatefulWidget {
  const SpendAdminScreen({super.key});

  @override
  State<SpendAdminScreen> createState() => _SpendAdminScreenState();
}

class _SpendAdminScreenState extends State<SpendAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _date;

  bool _loading = false;
  List<dynamic> _rows = [];

  @override
  void initState() {
    super.initState();
    _prefillSite();
    _refresh();
  }

  Future<void> _prefillSite() async {
    final siteId = await Api.storage.read(key: 'site_id');
    if (siteId != null) _siteIdCtrl.text = siteId;
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final q = <String, dynamic>{};
      if (_siteIdCtrl.text.isNotEmpty) q['siteId'] = _siteIdCtrl.text;
      final res = await Api.dio.get('/spend/all', queryParameters: q);
      setState(() => _rows = res.data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = {
      'site_id': _siteIdCtrl.text,
      'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
      'date': (_date ?? DateTime.now()).toIso8601String().substring(0, 10),
      'description': _descCtrl.text,
    };
    await Api.dio.post('/spend', data: body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spend saved')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spend Admin')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Wrap(
                runSpacing: 12,
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextFormField(
                      controller: _siteIdCtrl,
                      decoration: const InputDecoration(labelText: 'Site ID'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_date == null ? 'Date: Today' : 'Date: ${_date!.toIso8601String().substring(0,10)}'),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(now.year - 2),
                            lastDate: DateTime(now.year + 2),
                            initialDate: _date ?? now,
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  ElevatedButton(onPressed: _submit, child: const Text('Save')),
                  const SizedBox(width: 12),
                  BulkUploadButton(
                    bulkUrl: '/spend/bulk',
                    headerMap: const {
                      'siteId': 'site_id',
                    },
                    onDone: _refresh,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: _refresh, child: const Text('Refresh')),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final r = _rows[i] as Map<String, dynamic>;
                      final amt = r['amount'];
                      return ListTile(
                        leading: const Icon(Icons.payments),
                        title: Text(r['description']?.toString() ?? '-'),
                        subtitle: Text('${(r['date'] ?? '').toString().substring(0, 10)} • ${(r['site_id'] ?? '').toString().substring(0, 8)}'),
                        trailing: Text(amt == null ? '-' : amt.toString()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
