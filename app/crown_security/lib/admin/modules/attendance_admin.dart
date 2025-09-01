import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/entity_dropdown.dart';
import '../../core/api.dart';

class AttendanceAdmin extends StatelessWidget {
  const AttendanceAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Attendance',
      endpoint: '/attendance',
      searchField: 'guard_name',
      columns: [
        AdminColumn(field: 'guard_name', title: 'Guard', flex: 2),
        AdminColumn(field: 'date', title: 'Date'),
        AdminColumn(field: 'status', title: 'Status'),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'guard_name': item['guard_name'] ?? 'Unknown Guard',
        'date': _formatDate(item['date']),
        'status': item['status'] ?? '',
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
      buildCreateForm: (item) => AttendanceForm(
        isEdit: false,
        onSave: (data) async {
          await Api.dio.post('/attendance', data: data);
          Navigator.of(context).pop();
        },
      ),
      buildEditForm: (item) => AttendanceForm(
        isEdit: true,
        initialData: item,
        onSave: (data) async {
          await Api.dio.put('/attendance/${item['id']}', data: data);
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

class AttendanceForm extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const AttendanceForm({
    super.key,
    required this.isEdit,
    this.initialData,
    required this.onSave,
  });

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  final _formKey = GlobalKey<FormState>();
  String? _guardId;
  String? _siteId;
  DateTime? _date;
  String _status = 'PRESENT';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _guardId = widget.initialData!['guard_id'];
      _siteId = widget.initialData!['site_id'];
      _status = widget.initialData!['status'] ?? 'PRESENT';
      if (widget.initialData!['date'] != null) {
        _date = DateTime.tryParse(widget.initialData!['date'].toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EntityDropdown(
            endpoint: '/guards',
            valueField: 'id',
            displayField: 'name',
            label: 'Guard',
            required: true,
            value: _guardId,
            onChanged: (value) {
              setState(() {
                _guardId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          EntityDropdown(
            endpoint: '/sites',
            valueField: 'id',
            displayField: 'name',
            label: 'Site',
            required: true,
            value: _siteId,
            onChanged: (value) {
              setState(() {
                _siteId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _date = date);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date *',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _date?.toString().substring(0, 10) ?? 'Select Date',
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'PRESENT', child: Text('Present')),
              DropdownMenuItem(value: 'ABSENT', child: Text('Absent')),
              DropdownMenuItem(value: 'LEAVE', child: Text('Leave')),
            ],
            onChanged: (value) {
              setState(() {
                _status = value!;
              });
            },
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
                  : Text(widget.isEdit ? 'Update Attendance' : 'Create Attendance'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final data = {
        'guard_id': _guardId,
        'site_id': _siteId,
        'date': _date!.toIso8601String().substring(0, 10),
        'status': _status,
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
    super.dispose();
  }
}
