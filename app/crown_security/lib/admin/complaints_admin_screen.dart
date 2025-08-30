import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';

class ComplaintsAdminScreen extends StatefulWidget {
  const ComplaintsAdminScreen({super.key});

  @override
  State<ComplaintsAdminScreen> createState() => _ComplaintsAdminScreenState();
}

class _ComplaintsAdminScreenState extends State<ComplaintsAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteIdCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _statusCtrl = TextEditingController(text: 'OPEN');
  final _textCtrl = TextEditingController();

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
      final res = await Api.dio.get('/complaints', queryParameters: q);
      setState(() => _rows = res.data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = {
      'site_id': _siteIdCtrl.text,
      'complaint_text': _textCtrl.text,
      if (_clientIdCtrl.text.isNotEmpty) 'client_id': _clientIdCtrl.text,
      'status': _statusCtrl.text,
    };
    await Api.dio.post('/complaints/admin', data: body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint saved')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints Admin')),
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
                SizedBox(width: 220, child: TextFormField(controller: _clientIdCtrl, decoration: const InputDecoration(labelText: 'Client ID (optional)'))),
                SizedBox(width: 140, child: TextFormField(controller: _statusCtrl, decoration: const InputDecoration(labelText: 'Status'))),
                SizedBox(width: 360, child: TextFormField(controller: _textCtrl, minLines: 1, maxLines: 3, decoration: const InputDecoration(labelText: 'Complaint Text'), validator:(v)=> (v==null||v.isEmpty)?'Required':null)),
                ElevatedButton(onPressed: _submit, child: const Text('Save')),
                const SizedBox(width: 12),
                BulkUploadButton(bulkUrl: '/complaints/bulk', headerMap: const {'siteId':'site_id'}, onDone: _refresh),
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
                      leading: const Icon(Icons.report_problem),
                      title: Text((r['complaint_text'] ?? '').toString()),
                      subtitle: Text('${(r['createdAt'] ?? '').toString().substring(0,19)} • ${(r['status'] ?? '').toString()}'),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
