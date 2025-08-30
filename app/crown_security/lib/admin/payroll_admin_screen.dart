import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';

class PayrollAdminScreen extends StatefulWidget {
  const PayrollAdminScreen({super.key});

  @override
  State<PayrollAdminScreen> createState() => _PayrollAdminScreenState();
}

class _PayrollAdminScreenState extends State<PayrollAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteIdCtrl = TextEditingController();
  final _monthCtrl = TextEditingController(); // YYYY-MM
  final _statusCtrl = TextEditingController(text: 'PENDING');
  DateTime? _datePaid;

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
      final res = await Api.dio.get('/payroll', queryParameters: q);
      setState(() => _rows = res.data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = {
      'site_id': _siteIdCtrl.text,
      'month': DateTime.tryParse('${_monthCtrl.text}-01')?.toIso8601String(),
      'status': _statusCtrl.text,
      if (_datePaid != null) 'date_paid': _datePaid!.toIso8601String().substring(0,10),
    };
    await Api.dio.post('/payroll', data: body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll saved')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Admin')),
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
                SizedBox(width: 140, child: TextFormField(controller: _monthCtrl, decoration: const InputDecoration(labelText: 'Month (YYYY-MM)'), validator:(v)=> (v==null||v.length!=7)?'YYYY-MM':null)),
                SizedBox(width: 160, child: TextFormField(controller: _statusCtrl, decoration: const InputDecoration(labelText: 'Status'))),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_datePaid == null ? 'Paid Date: -' : 'Paid: ${_datePaid!.toIso8601String().substring(0,10)}'),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(context: context, firstDate: DateTime(now.year-2), lastDate: DateTime(now.year+2), initialDate: _datePaid ?? now);
                    if (picked != null) setState(()=> _datePaid = picked);
                  }, child: const Text('Paid Date')),
                ]),
                ElevatedButton(onPressed: _submit, child: const Text('Save')),
                const SizedBox(width: 12),
                BulkUploadButton(bulkUrl: '/payroll/bulk', headerMap: const {'siteId':'site_id','month':'month'}, onDone: _refresh),
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
                      leading: const Icon(Icons.payment),
                      title: Text('${(r['month'] ?? '').toString().substring(0,7)} • ${r['status'] ?? ''}'),
                      subtitle: Text('${(r['date_paid'] ?? '').toString().substring(0,10)} • ${(r['site_id'] ?? '').toString().substring(0,8)}'),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
