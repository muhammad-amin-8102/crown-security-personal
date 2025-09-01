import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/entity_dropdown.dart';
import '../../core/api.dart';

class SpendAdmin extends StatelessWidget {
  const SpendAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Spend',
      endpoint: '/spend/all',
      columns: [
        AdminColumn(field: 'date', title: 'Date'),
        AdminColumn(field: 'amount', title: 'Amount'),
        AdminColumn(field: 'description', title: 'Description', flex: 2),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'date': _formatDate(item['date']),
        'amount': item['amount']?.toString() ?? '',
        'description': item['description'] ?? '',
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
      buildCreateForm: (item) => SpendForm(
        isEdit: false,
        onSave: (data) async {
          await Api.dio.post('/spend', data: data);
          Navigator.of(context).pop();
        },
      ),
      buildEditForm: (item) => SpendForm(
        isEdit: true,
        initialData: item,
        onSave: (data) async {
          await Api.dio.put('/spend/${item['id']}', data: data);
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

class SpendForm extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const SpendForm({
    super.key,
    required this.isEdit,
    this.initialData,
    required this.onSave,
  });

  @override
  State<SpendForm> createState() => _SpendFormState();
}

class _SpendFormState extends State<SpendForm> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSiteId;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _dateController.text = data['date']?.toString().substring(0, 10) ?? '';
      _amountController.text = data['amount']?.toString() ?? '';
      _descriptionController.text = data['description']?.toString() ?? '';
      _selectedSiteId = data['site_id']?.toString();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
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
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'description': _descriptionController.text,
        'site_id': _selectedSiteId,
      };
      widget.onSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Spend' : 'Add Spend'),
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
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Amount is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
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
