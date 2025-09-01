import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/entity_dropdown.dart';
import '../../core/api.dart';

class SitesAdmin extends StatelessWidget {
  const SitesAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Sites',
      endpoint: '/sites',
      searchField: 'name',
      columns: [
        AdminColumn(field: 'name', title: 'Name', flex: 2),
        AdminColumn(field: 'location', title: 'Location', flex: 2),
        AdminColumn(field: 'strength', title: 'Strength'),
        AdminColumn(field: 'rate', title: 'Rate'),
        AdminColumn(field: 'client_name', title: 'Client', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'name': item['name'] ?? '',
        'location': item['location'] ?? '',
        'strength': item['strength']?.toString() ?? '',
        'rate': item['rate']?.toString() ?? '',
        'client_name': item['client_name'] ?? 'No Client',
      },
      buildCreateForm: (item) => SiteForm(
        isEdit: false,
        onSave: (data) async {
          await Api.dio.post('/sites', data: data);
          Navigator.of(context).pop();
        },
      ),
      buildEditForm: (item) => SiteForm(
        isEdit: true,
        initialData: item,
        onSave: (data) async {
          await Api.dio.put('/sites/${item['id']}', data: data);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class SiteForm extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const SiteForm({
    super.key,
    required this.isEdit,
    this.initialData,
    required this.onSave,
  });

  @override
  State<SiteForm> createState() => _SiteFormState();
}

class _SiteFormState extends State<SiteForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _strengthController = TextEditingController();
  final _rateController = TextEditingController();
  final _officerNameController = TextEditingController();
  final _officerPhoneController = TextEditingController();
  final _croNameController = TextEditingController();
  final _croPhoneController = TextEditingController();
  String? _clientId;
  DateTime? _agreementStart;
  DateTime? _agreementEnd;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _locationController.text = widget.initialData!['location'] ?? '';
      _strengthController.text = widget.initialData!['strength']?.toString() ?? '';
      _rateController.text = widget.initialData!['rate']?.toString() ?? '';
      _officerNameController.text = widget.initialData!['officer_name'] ?? widget.initialData!['officerName'] ?? '';
      _officerPhoneController.text = widget.initialData!['officer_phone'] ?? widget.initialData!['officerPhone'] ?? '';
      _croNameController.text = widget.initialData!['cro_name'] ?? widget.initialData!['croName'] ?? '';
      _croPhoneController.text = widget.initialData!['cro_phone'] ?? widget.initialData!['croPhone'] ?? '';
      _clientId = widget.initialData!['client_id'] ?? widget.initialData!['clientId'];
      
      if (widget.initialData!['agreement_start'] != null) {
        _agreementStart = DateTime.tryParse(widget.initialData!['agreement_start'].toString());
      }
      if (widget.initialData!['agreement_end'] != null) {
        _agreementEnd = DateTime.tryParse(widget.initialData!['agreement_end'].toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Site Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Site name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _strengthController,
                    decoration: const InputDecoration(
                      labelText: 'Strength',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            EntityDropdown(
              endpoint: '/users?role=CLIENT',
              valueField: 'id',
              displayField: 'name',
              label: 'Client',
              required: false,
              value: _clientId,
              onChanged: (value) {
                setState(() {
                  _clientId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _officerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Officer Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _officerPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Officer Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _croNameController,
                    decoration: const InputDecoration(
                      labelText: 'CRO Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _croPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'CRO Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _agreementStart ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _agreementStart = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Agreement Start',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _agreementStart?.toString().substring(0, 10) ?? 'Select Date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _agreementEnd ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _agreementEnd = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Agreement End',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _agreementEnd?.toString().substring(0, 10) ?? 'Select Date',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCFAE02),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(widget.isEdit ? 'Update Site' : 'Create Site'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameController.text,
        'location': _locationController.text,
        if (_strengthController.text.isNotEmpty)
          'strength': int.tryParse(_strengthController.text),
        if (_rateController.text.isNotEmpty)
          'rate': double.tryParse(_rateController.text),
        if (_clientId != null && _clientId!.isNotEmpty)
          'client_id': _clientId,
        if (_officerNameController.text.isNotEmpty)
          'officer_name': _officerNameController.text,
        if (_officerPhoneController.text.isNotEmpty)
          'officer_phone': _officerPhoneController.text,
        if (_croNameController.text.isNotEmpty)
          'cro_name': _croNameController.text,
        if (_croPhoneController.text.isNotEmpty)
          'cro_phone': _croPhoneController.text,
        if (_agreementStart != null)
          'agreement_start': _agreementStart!.toIso8601String().substring(0, 10),
        if (_agreementEnd != null)
          'agreement_end': _agreementEnd!.toIso8601String().substring(0, 10),
      };

      await widget.onSave(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _strengthController.dispose();
    _rateController.dispose();
    _officerNameController.dispose();
    _officerPhoneController.dispose();
    _croNameController.dispose();
    _croPhoneController.dispose();
    super.dispose();
  }
}
