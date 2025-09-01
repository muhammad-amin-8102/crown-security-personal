import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/entity_dropdown.dart';
import '../../core/api.dart';

class ShiftsAdmin extends StatelessWidget {
  const ShiftsAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Shifts',
      endpoint: '/shifts/list/all',
      columns: [
        AdminColumn(field: 'date', title: 'Date'),
        AdminColumn(field: 'shift_type', title: 'Type'),
        AdminColumn(field: 'guard_count', title: 'Guards'),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'date': item['date']?.toString().substring(0, 10) ?? '',
        'shift_type': item['shift_type'] ?? '',
        'guard_count': item['guard_count']?.toString() ?? '',
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
      buildCreateForm: (item) => ShiftForm(
        isEdit: false,
        onSave: (data) async {
          await Api.dio.post('/shifts', data: data);
          Navigator.of(context).pop();
        },
      ),
      buildEditForm: (item) => ShiftForm(
        isEdit: true,
        initialData: item,
        onSave: (data) async {
          await Api.dio.put('/shifts/${item['id']}', data: data);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class ShiftForm extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const ShiftForm({
    super.key,
    required this.isEdit,
    this.initialData,
    required this.onSave,
  });

  @override
  State<ShiftForm> createState() => _ShiftFormState();
}

class _ShiftFormState extends State<ShiftForm> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _shiftTypeController = TextEditingController();
  final _guardCountController = TextEditingController();
  String? _selectedSiteId;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _dateController.text = data['date']?.toString().substring(0, 10) ?? '';
      _shiftTypeController.text = data['shift_type']?.toString() ?? '';
      _guardCountController.text = data['guard_count']?.toString() ?? '';
      _selectedSiteId = data['site_id']?.toString();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _shiftTypeController.dispose();
    _guardCountController.dispose();
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
        'shift_type': _shiftTypeController.text,
        'guard_count': int.tryParse(_guardCountController.text) ?? 0,
        'site_id': _selectedSiteId,
      };
      widget.onSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Shift' : 'Add Shift'),
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
              controller: _shiftTypeController,
              decoration: const InputDecoration(labelText: 'Shift Type'),
              validator: (value) => value?.isEmpty ?? true ? 'Shift type is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _guardCountController,
              decoration: const InputDecoration(labelText: 'Guard Count'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Guard count is required' : null,
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
