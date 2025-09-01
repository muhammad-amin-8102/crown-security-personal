import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../../core/api.dart';

class UsersAdmin extends StatelessWidget {
  const UsersAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Users',
      endpoint: '/users',
      searchField: 'name',
      columns: [
        AdminColumn(field: 'name', title: 'Name', flex: 2),
        AdminColumn(field: 'email', title: 'Email', flex: 2),
        AdminColumn(field: 'phone', title: 'Phone'),
        AdminColumn(field: 'role', title: 'Role'),
        AdminColumn(field: 'active', title: 'Status'),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'name': item['name'] ?? '',
        'email': item['email'] ?? '',
        'phone': _formatPhone(item['phone']),
        'role': item['role'] ?? '',
        'active': (item['active'] == true) ? 'Active' : 'Inactive',
      },
      buildCreateForm: (item) => UserForm(
        isEdit: false,
        onSave: (data) async {
          await Api.dio.post('/users', data: data);
          Navigator.of(context).pop();
        },
      ),
      buildEditForm: (item) => UserForm(
        isEdit: true,
        initialData: item,
        onSave: (data) async {
          await Api.dio.put('/users/${item['id']}', data: data);
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

class UserForm extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const UserForm({
    super.key,
    required this.isEdit,
    this.initialData,
    required this.onSave,
  });

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'CLIENT';
  bool _active = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _phoneController.text = widget.initialData!['phone'] ?? '';
      _role = widget.initialData!['role'] ?? 'CLIENT';
      _active = widget.initialData!['active'] ?? true;
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
              labelText: 'Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Enter a valid email';
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
          if (!widget.isEdit) ...[
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password *',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
              DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
              DropdownMenuItem(value: 'OFFICER', child: Text('Officer')),
              DropdownMenuItem(value: 'CRO', child: Text('CRO')),
            ],
            onChanged: (value) {
              setState(() {
                _role = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Active'),
            value: _active,
            onChanged: (value) {
              setState(() {
                _active = value!;
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
                  : Text(widget.isEdit ? 'Update User' : 'Create User'),
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
        'email': _emailController.text,
        'phone': _phoneController.text,
        'role': _role,
        'active': _active,
      };

      if (!widget.isEdit) {
        data['password'] = _passwordController.text;
      }

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
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
