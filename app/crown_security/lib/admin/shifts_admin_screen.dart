import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';

class ShiftsAdminScreen extends StatefulWidget {
  const ShiftsAdminScreen({super.key});

  @override
  State<ShiftsAdminScreen> createState() => _ShiftsAdminScreenState();
}

class _ShiftsAdminScreenState extends State<ShiftsAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteIdCtrl = TextEditingController();
  DateTime? _date;
  final _shiftTypeCtrl = TextEditingController(text: 'DAY');
  final _guardCountCtrl = TextEditingController(text: '0');

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
      final res = await Api.dio.get('/shifts/list/all', queryParameters: q);
      setState(() => _rows = res.data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = {
      'site_id': _siteIdCtrl.text,
      'date': (_date ?? DateTime.now()).toIso8601String().substring(0, 10),
      'shift_type': _shiftTypeCtrl.text,
      'guard_count': int.tryParse(_guardCountCtrl.text) ?? 0,
    };
    await Api.dio.post('/shifts', data: body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift saved')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shifts Admin')),
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
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      controller: _shiftTypeCtrl,
                      decoration: const InputDecoration(labelText: 'Shift Type (DAY/NIGHT/etc)'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: _guardCountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Guard Count'),
                    ),
                  ),
                  ElevatedButton(onPressed: _submit, child: const Text('Save')),
                  const SizedBox(width: 12),
                  BulkUploadButton(
                    bulkUrl: '/shifts/bulk',
                    headerMap: const {
                      'siteId': 'site_id',
                      'shiftType': 'shift_type',
                      'guardCount': 'guard_count',
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
                      return ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text('${r['shift_type'] ?? '-'} • guards ${r['guard_count'] ?? 0}'),
                        subtitle: Text('${(r['date'] ?? '').toString().substring(0, 10)}  |  ${(r['site_id'] ?? '').toString().substring(0, 8)}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
