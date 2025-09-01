import 'package:flutter/material.dart';
import '../../core/api.dart';

class EntityDropdown extends StatefulWidget {
  final String endpoint;
  final String valueField;
  final String displayField;
  final String? value;
  final String label;
  final bool required;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const EntityDropdown({
    super.key,
    required this.endpoint,
    required this.valueField,
    required this.displayField,
    this.value,
    required this.label,
    this.required = false,
    required this.onChanged,
    this.validator,
  });

  @override
  State<EntityDropdown> createState() => _EntityDropdownState();
}

class _EntityDropdownState extends State<EntityDropdown> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final response = await Api.dio.get(widget.endpoint);
      final data = response.data as List;
      setState(() {
        _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load ${widget.label.toLowerCase()}s';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: '${widget.label}${widget.required ? ' *' : ''}',
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                const Text('Loading...'),
              ],
            ),
          ),
        ],
        onChanged: null,
      );
    }

    if (_error != null) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: '${widget.label}${widget.required ? ' *' : ''}',
          border: const OutlineInputBorder(),
          errorText: _error,
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(_error!),
              ],
            ),
          ),
        ],
        onChanged: null,
      );
    }

    return DropdownButtonFormField<String>(
      value: widget.value,
      decoration: InputDecoration(
        labelText: '${widget.label}${widget.required ? ' *' : ''}',
        border: const OutlineInputBorder(),
      ),
      validator: widget.validator ?? (widget.required ? (value) {
        if (value == null || value.isEmpty) {
          return '${widget.label} is required';
        }
        return null;
      } : null),
      items: [
        if (!widget.required)
          const DropdownMenuItem(
            value: null,
            child: Text('-- Select --'),
          ),
        ..._items.map((item) {
          final value = item[widget.valueField]?.toString();
          final display = item[widget.displayField]?.toString() ?? 'Unknown';
          return DropdownMenuItem(
            value: value,
            child: Text(display),
          );
        }),
      ],
      onChanged: widget.onChanged,
    );
  }
}
