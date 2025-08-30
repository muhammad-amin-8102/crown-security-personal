import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';

class BillsAdminScreen extends StatefulWidget {
  const BillsAdminScreen({super.key});

  @override
  State<BillsAdminScreen> createState() => _BillsAdminScreenState();
}

class _BillsAdminScreenState extends State<BillsAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _statusCtrl = TextEditingController(text: 'OUTSTANDING');
  final _invoiceUrlCtrl = TextEditingController();
  DateTime? _dueDate;

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
      final res = await Api.dio.get('/billing/soa', queryParameters: q);
      final data = res.data as Map<String, dynamic>;
      setState(() => _rows = (data['items'] as List<dynamic>)..sort((a,b)=> (a['due_date']??'').toString().compareTo((b['due_date']??'').toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = {
      'site_id': _siteIdCtrl.text,
      'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
      'due_date': (_dueDate ?? DateTime.now()).toIso8601String().substring(0, 10),
      'status': _statusCtrl.text,
      if (_invoiceUrlCtrl.text.isNotEmpty) 'invoice_url': _invoiceUrlCtrl.text,
    };
    await Api.dio.post('/billing', data: body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill saved')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bills (SOA) Admin')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Wrap(
              runSpacing: 12,
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(width: 260, child: TextFormField(controller: _siteIdCtrl, decoration: const InputDecoration(labelText: 'Site ID'), validator: (v)=> (v==null||v.isEmpty)?'Required':null)),
                SizedBox(width: 140, child: TextFormField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount'), validator:(v)=> (v==null||v.isEmpty)?'Required':null)),
                SizedBox(width: 180, child: TextFormField(controller: _statusCtrl, decoration: const InputDecoration(labelText: 'Status'))),
                SizedBox(width: 240, child: TextFormField(controller: _invoiceUrlCtrl, decoration: const InputDecoration(labelText: 'Invoice URL (optional)'))),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_dueDate == null ? 'Due: Today' : 'Due: ${_dueDate!.toIso8601String().substring(0,10)}'),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(context: context, firstDate: DateTime(now.year-2), lastDate: DateTime(now.year+2), initialDate: _dueDate ?? now);
                    if (picked != null) setState(()=> _dueDate = picked);
                  }, child: const Text('Pick Due Date')),
                ]),
                ElevatedButton(onPressed: _submit, child: const Text('Save')),
                const SizedBox(width: 12),
                BulkUploadButton(bulkUrl: '/billing/bulk', headerMap: const {'siteId':'site_id'}, onDone: _refresh),
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
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text('₹${r['amount']} • ${r['status']}'),
                      subtitle: Text('${(r['due_date'] ?? '').toString().substring(0,10)} • ${(r['site_id'] ?? '').toString().substring(0,8)}'),
                      trailing: Text((r['invoice_url'] ?? '').toString()),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
