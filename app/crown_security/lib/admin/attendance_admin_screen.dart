import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';

class AttendanceAdminScreen extends StatefulWidget {
  const AttendanceAdminScreen({super.key});

  @override
  State<AttendanceAdminScreen> createState() => _AttendanceAdminScreenState();
}

class _AttendanceAdminScreenState extends State<AttendanceAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteIdCtrl = TextEditingController();
  final _guardIdCtrl = TextEditingController();
  DateTime? _date;
  String _status = 'PRESENT';

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
      final res = await Api.dio.get('/attendance', queryParameters: q);
      setState(() => _rows = res.data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = {
      'site_id': _siteIdCtrl.text,
      'guard_id': _guardIdCtrl.text,
      'date': (_date ?? DateTime.now()).toIso8601String().substring(0, 10),
      'status': _status,
    };
    await Api.dio.post('/attendance', data: body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Admin')),
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
                    width: 220,
                    child: TextFormField(
                      controller: _guardIdCtrl,
                      decoration: const InputDecoration(labelText: 'Guard ID'),
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
                  DropdownButton<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'PRESENT', child: Text('PRESENT')),
                      DropdownMenuItem(value: 'ABSENT', child: Text('ABSENT')),
                      DropdownMenuItem(value: 'LEAVE', child: Text('LEAVE')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'PRESENT'),
                  ),
                  ElevatedButton(onPressed: _submit, child: const Text('Save')),
                  const SizedBox(width: 12),
                  BulkUploadButton(
                    bulkUrl: '/attendance/bulk',
                    headerMap: const {
                      'siteId': 'site_id',
                      'guardId': 'guard_id',
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
                        leading: const Icon(Icons.badge),
                        title: Text('${r['guard_id'] ?? '-'} • ${r['status'] ?? '-'}'),
                        subtitle: Text('${(r['date'] ?? '').toString().substring(0, 10)}  |  site ${(r['site_id'] ?? '').toString().substring(0, 8)}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
