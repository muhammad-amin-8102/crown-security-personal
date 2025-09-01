import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/entity_dropdown.dart';
import '../../core/api.dart';

class GuardsAdmin extends StatelessWidget {
  const GuardsAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Guards',
      endpoint: '/guards',
      searchField: 'name',
      columns: [
        AdminColumn(field: 'name', title: 'Name', flex: 2),
        AdminColumn(field: 'phone', title: 'Phone'),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'name': item['name'] ?? '',
        'phone': _formatPhone(item['phone']),
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
      buildCreateForm: (item) => GuardForm(
        isEdit: false,
        onSave: (data) async {
          await Api.dio.post('/guards', data: data);
          Navigator.of(context).pop();
        },
      ),
      buildEditForm: (item) => GuardForm(
        isEdit: true,
        initialData: item,
        onSave: (data) async {
          await Api.dio.put('/guards/${item['id']}', data: data);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  static String _formatPhone(dynamic phone) {
    if (phone == null) return '';
    final phoneStr = phone.toString();
    if (phoneStr.length >= 10) {
      return phoneStr.substring(phoneStr.length - 10);
    }
    return phoneStr;
  }
}

class GuardForm extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const GuardForm({
    super.key,
    required this.isEdit,
    this.initialData,
    required this.onSave,
  });

  @override
  State<GuardForm> createState() => _GuardFormState();
}

class _GuardFormState extends State<GuardForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _siteId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _phoneController.text = widget.initialData!['phone'] ?? '';
      _siteId = widget.initialData!['site_id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Guard Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Guard name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone is required';
              }
              if (value.length < 10) {
                return 'Phone must be at least 10 digits';
              }
              return null;
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
                  : Text(widget.isEdit ? 'Update Guard' : 'Create Guard'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'site_id': _siteId,
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
    _phoneController.dispose();
    super.dispose();
  }
}
