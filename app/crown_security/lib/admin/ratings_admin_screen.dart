import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';

class RatingsAdminScreen extends StatefulWidget {
  const RatingsAdminScreen({super.key});

  @override
  State<RatingsAdminScreen> createState() => _RatingsAdminScreenState();
}

class _RatingsAdminScreenState extends State<RatingsAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteIdCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _monthCtrl = TextEditingController(); // YYYY-MM
  final _ratingCtrl = TextEditingController();
  final _npsCtrl = TextEditingController();

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
      final res = await Api.dio.get('/ratings', queryParameters: q);
      setState(() => _rows = res.data as List<dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = {
      'site_id': _siteIdCtrl.text,
      'client_id': _clientIdCtrl.text.isEmpty ? null : _clientIdCtrl.text,
      'month': _monthCtrl.text,
      'rating_value': double.tryParse(_ratingCtrl.text) ?? 0,
      'nps_score': int.tryParse(_npsCtrl.text) ?? 0,
    };
    await Api.dio.post('/ratings/admin', data: body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating saved')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ratings & NPS Admin')),
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
                SizedBox(width: 140, child: TextFormField(controller: _monthCtrl, decoration: const InputDecoration(labelText: 'Month (YYYY-MM)'), validator:(v)=> (v==null||v.length!=7)?'YYYY-MM':null)),
                SizedBox(width: 120, child: TextFormField(controller: _ratingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rating (0-5)'))),
                SizedBox(width: 120, child: TextFormField(controller: _npsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'NPS (0-10)'))),
                ElevatedButton(onPressed: _submit, child: const Text('Save')),
                const SizedBox(width: 12),
                BulkUploadButton(bulkUrl: '/ratings/bulk', headerMap: const {'siteId':'site_id','month':'month'}, onDone: _refresh),
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
                      leading: const Icon(Icons.star),
                      title: Text('${(r['month'] ?? '').toString().substring(0,7)} • Rating ${r['rating_value'] ?? r['rating']} • NPS ${r['nps_score'] ?? r['npsScore']}'),
                      subtitle: Text((r['site_id'] ?? '').toString().substring(0,8)),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
