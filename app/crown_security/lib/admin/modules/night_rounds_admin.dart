import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/entity_dropdown.dart';
import '../../core/api.dart';

class NightRoundsAdmin extends StatelessWidget {
  const NightRoundsAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Night Rounds',
      endpoint: '/night-rounds',
      columns: [
        AdminColumn(field: 'date', title: 'Date'),
        AdminColumn(field: 'officer_name', title: 'Officer', flex: 2),
        AdminColumn(field: 'findings', title: 'Findings', flex: 3),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'date': _formatDate(item['date']),
        'officer_name': item['officer_name'] ?? 'Unknown Officer',
        'findings': item['findings'] ?? '',
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
      buildCreateForm: (item) => NightRoundForm(
        isEdit: false,
        onSave: (data) async {
          await Api.dio.post('/night-rounds', data: data);
          Navigator.of(context).pop();
        },
      ),
      buildEditForm: (item) => NightRoundForm(
        isEdit: true,
        initialData: item,
        onSave: (data) async {
          await Api.dio.put('/night-rounds/${item['id']}', data: data);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '';
    final d = DateTime.tryParse(date.toString());
    if (d == null) return date.toString();
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }
}

class NightRoundForm extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const NightRoundForm({
    super.key,
    required this.isEdit,
    this.initialData,
    required this.onSave,
  });

  @override
  State<NightRoundForm> createState() => _NightRoundFormState();
}

class _NightRoundFormState extends State<NightRoundForm> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _findingsController = TextEditingController();
  String? _selectedOfficerId;
  String? _selectedSiteId;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _dateController.text = data['date']?.toString().substring(0, 10) ?? '';
      _findingsController.text = data['findings']?.toString() ?? '';
      _selectedOfficerId = data['officer_id']?.toString();
      _selectedSiteId = data['site_id']?.toString();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _findingsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      _dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'date': _dateController.text,
        'findings': _findingsController.text,
        'officer_id': _selectedOfficerId,
        'site_id': _selectedSiteId,
      };
      widget.onSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Night Round' : 'Add Night Round'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ),
              readOnly: true,
              validator: (value) => value?.isEmpty ?? true ? 'Date is required' : null,
            ),
            const SizedBox(height: 16),
            EntityDropdown(
              label: 'Officer',
              endpoint: '/guards',
              valueField: 'id',
              displayField: 'name',
              value: _selectedOfficerId,
              onChanged: (value) => setState(() => _selectedOfficerId = value),
              validator: (value) => value == null ? 'Officer is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _findingsController,
              decoration: const InputDecoration(labelText: 'Findings'),
              maxLines: 4,
              validator: (value) => value?.isEmpty ?? true ? 'Findings are required' : null,
            ),
            const SizedBox(height: 16),
            EntityDropdown(
              label: 'Site',
              endpoint: '/sites',
              valueField: 'id',
              displayField: 'name',
              value: _selectedSiteId,
              onChanged: (value) => setState(() => _selectedSiteId = value),
              validator: (value) => value == null ? 'Site is required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
