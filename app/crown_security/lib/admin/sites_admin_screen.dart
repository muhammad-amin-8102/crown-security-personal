import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';

class SitesAdminScreen extends StatefulWidget {
  const SitesAdminScreen({super.key});

  @override
  State<SitesAdminScreen> createState() => _SitesAdminScreenState();
}

class _SitesAdminScreenState extends State<SitesAdminScreen> {
  bool _loading = false;
  List<dynamic> _rows = [];

  final _siteIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final res = await Api.dio.get('/sites');
      setState(() => _rows = res.data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _patch() async {
    if (_siteIdCtrl.text.isEmpty) return;
    final body = {
      if (_nameCtrl.text.isNotEmpty) 'name': _nameCtrl.text,
      if (_locCtrl.text.isNotEmpty) 'location': _locCtrl.text,
      if (_strengthCtrl.text.isNotEmpty) 'strength': int.tryParse(_strengthCtrl.text),
      if (_rateCtrl.text.isNotEmpty) 'rate_per_guard': double.tryParse(_rateCtrl.text),
    };
    await Api.dio.patch('/sites/${_siteIdCtrl.text}', data: body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site updated')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sites Admin')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            runSpacing: 12,
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: 240, child: TextField(controller: _siteIdCtrl, decoration: const InputDecoration(labelText: 'Site ID (for single patch)'))),
              SizedBox(width: 200, child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name'))),
              SizedBox(width: 220, child: TextField(controller: _locCtrl, decoration: const InputDecoration(labelText: 'Location'))),
              SizedBox(width: 160, child: TextField(controller: _strengthCtrl, decoration: const InputDecoration(labelText: 'Strength'))),
              SizedBox(width: 160, child: TextField(controller: _rateCtrl, decoration: const InputDecoration(labelText: 'Rate per Guard'))),
              ElevatedButton(onPressed: _patch, child: const Text('Patch Site')),
              const SizedBox(width: 12),
              BulkUploadButton(
                bulkUrl: '/sites/bulk',
                headerMap: const {
                  'id': 'id',
                  'name': 'name',
                  'location': 'location',
                  'strength': 'strength',
                  'rate': 'rate_per_guard',
                  'agreementStart': 'agreement_start',
                  'agreementEnd': 'agreement_end',
                  'officerName': 'area_officer_name',
                  'officerPhone': 'area_officer_phone',
                  'croName': 'cro_name',
                  'croPhone': 'cro_phone',
                  'clientId': 'client_id',
                },
                onDone: _refresh,
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _refresh, child: const Text('Refresh')),
            ],
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
                      leading: const Icon(Icons.business),
                      title: Text(r['name']?.toString() ?? '-'),
                      subtitle: Text('${r['location'] ?? ''} • ${(r['id'] ?? '').toString().substring(0,8)}'),
                      trailing: Text('Strength ${r['strength'] ?? '-'}'),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
