import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/entity_dropdown.dart';
import '../../core/api.dart';

class TrainingAdmin extends StatelessWidget {
  const TrainingAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Training',
      endpoint: '/training',
      columns: [
        AdminColumn(field: 'date', title: 'Date'),
        AdminColumn(field: 'attendance_count', title: 'Attendance'),
        AdminColumn(field: 'topics', title: 'Topics', flex: 3),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'date': _formatDate(item['date']),
        'attendance_count': item['attendance_count']?.toString() ?? '',
        'topics': item['topics'] ?? '',
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
      buildCreateForm: (item) => TrainingForm(
        isEdit: false,
        onSave: (data) async {
          await Api.dio.post('/training', data: data);
          Navigator.of(context).pop();
        },
      ),
      buildEditForm: (item) => TrainingForm(
        isEdit: true,
        initialData: item,
        onSave: (data) async {
          await Api.dio.put('/training/${item['id']}', data: data);
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

class TrainingForm extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const TrainingForm({
    super.key,
    required this.isEdit,
    this.initialData,
    required this.onSave,
  });

  @override
  State<TrainingForm> createState() => _TrainingFormState();
}

class _TrainingFormState extends State<TrainingForm> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _attendanceController = TextEditingController();
  final _topicsController = TextEditingController();
  String? _selectedSiteId;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _dateController.text = data['date']?.toString().substring(0, 10) ?? '';
      _attendanceController.text = data['attendance_count']?.toString() ?? '';
      _topicsController.text = data['topics']?.toString() ?? '';
      _selectedSiteId = data['site_id']?.toString();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _attendanceController.dispose();
    _topicsController.dispose();
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
        'attendance_count': int.tryParse(_attendanceController.text) ?? 0,
        'topics': _topicsController.text,
        'site_id': _selectedSiteId,
      };
      widget.onSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Training' : 'Add Training'),
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
              controller: _attendanceController,
              decoration: const InputDecoration(labelText: 'Attendance Count'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Attendance count is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _topicsController,
              decoration: const InputDecoration(labelText: 'Topics'),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Topics are required' : null,
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
