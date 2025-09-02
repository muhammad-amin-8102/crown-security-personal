import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../core/api.dart';

class AdminDataTable extends StatefulWidget {
  final String title;
  final String endpoint;
  final List<AdminColumn> columns;
  final Map<String, dynamic> Function(Map<String, dynamic>) mapRowData;
  final Widget Function(Map<String, dynamic>)? buildCreateForm;
  final Widget Function(Map<String, dynamic>)? buildEditForm;
  final List<AdminFormField>? createFormFields;
  final List<AdminFormField>? editFormFields;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canBulkImport;
  final bool canExport;
  final String? searchField;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onCreateItem;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onUpdateItem;

  const AdminDataTable({
    super.key,
    required this.title,
    required this.endpoint,
    required this.columns,
    required this.mapRowData,
    this.buildCreateForm,
    this.buildEditForm,
    this.createFormFields,
    this.editFormFields,
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.canBulkImport = true,
    this.canExport = true,
    this.searchField,
    this.onCreateItem,
    this.onUpdateItem,
  });

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _loading = true;
  String _searchQuery = '';
  String _sortColumn = '';
  bool _sortAscending = true;
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Api.dio.get(widget.endpoint);
      final data = response.data as List;
      setState(() {
        _data = data.map((e) => Map<String, dynamic>.from(e)).toList();
        _filteredData = List.from(_data);
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredData = _data.where((item) {
        if (_searchQuery.isEmpty) return true;
        
        final searchField = widget.searchField ?? widget.columns.first.field;
        final value = item[searchField]?.toString().toLowerCase() ?? '';
        return value.contains(_searchQuery.toLowerCase());
      }).toList();

      if (_sortColumn.isNotEmpty) {
        _filteredData.sort((a, b) {
          final aVal = a[_sortColumn]?.toString() ?? '';
          final bVal = b[_sortColumn]?.toString() ?? '';
          final result = aVal.compareTo(bVal);
          return _sortAscending ? result : -result;
        });
      }
    });
  }

  void _sort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
    _applyFilters();
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Api.dio.delete('${widget.endpoint}/$id');
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredData.length);
    final pageData = _filteredData.sublist(startIndex, endIndex);
    final totalPages = (_filteredData.length / _itemsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              // Bulk operations
              if (widget.canExport) ...[
                OutlinedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.canBulkImport) ...[
                OutlinedButton.icon(
                  onPressed: _showImportDialog,
                  icon: const Icon(Icons.upload),
                  label: const Text('Import'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _downloadTemplate,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Template'),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.canCreate)
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCFAE02),
                    foregroundColor: Colors.black,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Search and filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.title.toLowerCase()}...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _currentPage = 1;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data table
          Expanded(
            child: Card(
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        ...widget.columns.map((column) => Expanded(
                          flex: column.flex,
                          child: InkWell(
                            onTap: () => _sort(column.field),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text(
                                    column.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_sortColumn == column.field) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      _sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )),
                        if (widget.canEdit || widget.canDelete)
                          const SizedBox(
                            width: 120,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Actions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Table rows
                  Expanded(
                    child: pageData.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: pageData.length,
                            itemBuilder: (context, index) {
                              final row = widget.mapRowData(pageData[index]);
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ...widget.columns.map((column) => Expanded(
                                      flex: column.flex,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          row[column.field]?.toString() ?? '-',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    )),
                                    if (widget.canEdit || widget.canDelete)
                                      SizedBox(
                                        width: 120,
                                        child: Row(
                                          children: [
                                            if (widget.canEdit && widget.buildEditForm != null)
                                              IconButton(
                                                onPressed: () => _showEditDialog(pageData[index]),
                                                icon: const Icon(Icons.edit, size: 18),
                                                tooltip: 'Edit',
                                              ),
                                            if (widget.canDelete)
                                              IconButton(
                                                onPressed: () => _deleteItem(
                                                  pageData[index]['id']?.toString() ?? '',
                                                ),
                                                icon: const Icon(Icons.delete, size: 18),
                                                tooltip: 'Delete',
                                                color: Colors.red,
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Pagination
                  if (totalPages > 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${startIndex + 1}-$endIndex of ${_filteredData.length} items',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _currentPage > 1
                                    ? () => setState(() => _currentPage--)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text(
                                'Page $_currentPage of $totalPages',
                                style: const TextStyle(fontSize: 14),
                              ),
                              IconButton(
                                onPressed: _currentPage < totalPages
                                    ? () => setState(() => _currentPage++)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    try {
      final csvContent = _generateCSV(_data);
      final bytes = const Utf8Encoder().convert(csvContent);
      
      await FileSaver.instance.saveFile(
        name: '${widget.title.toLowerCase().replaceAll(' ', '_')}_export_${DateTime.now().millisecondsSinceEpoch}',
        bytes: Uint8List.fromList(bytes),
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _downloadTemplate() async {
    try {
      final templateContent = _generateTemplate();
      final bytes = const Utf8Encoder().convert(templateContent);
      
      await FileSaver.instance.saveFile(
        name: '${widget.title.toLowerCase().replaceAll(' ', '_')}_template',
        bytes: Uint8List.fromList(bytes),
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template download failed: $e')),
        );
      }
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import ${widget.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a CSV file to import. Make sure the columns match the template format.',
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _selectImportFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select CSV File'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _selectImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _processImportFile(file.bytes!);
        } else {
          throw Exception('File content is empty');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _processImportFile(Uint8List bytes) async {
    try {
      final content = const Utf8Decoder().convert(bytes);
      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.isEmpty) {
        throw Exception('File is empty');
      }

      final headers = lines.first.split(',').map((h) => h.trim()).toList();
      final dataRows = lines.skip(1).toList();

      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (int i = 0; i < dataRows.length; i++) {
        try {
          final values = dataRows[i].split(',').map((v) => v.trim()).toList();
          final rowData = <String, dynamic>{};
          
          for (int j = 0; j < headers.length && j < values.length; j++) {
            rowData[headers[j]] = values[j];
          }

          // Process the row data if needed
          final processedData = widget.onCreateItem != null 
              ? await widget.onCreateItem!(rowData)
              : rowData;

          await Api.dio.post(widget.endpoint, data: processedData);
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('Row ${i + 2}: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close import dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed: $successCount successful, $errorCount failed',
            ),
            backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          ),
        );

        if (errors.isNotEmpty && errors.length <= 5) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Errors'),
              content: Text(errors.join('\n')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        _loadData(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import processing failed: $e')),
        );
      }
    }
  }

  String _generateCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    
    final headers = widget.columns.map((col) => col.field).toList();
    final csvLines = <String>[];
    
    // Add headers
    csvLines.add(headers.join(','));
    
    // Add data rows
    for (final item in data) {
      final mappedItem = widget.mapRowData(item);
      final row = headers.map((header) => 
        '"${mappedItem[header]?.toString().replaceAll('"', '""') ?? ''}"'
      ).join(',');
      csvLines.add(row);
    }
    
    return csvLines.join('\n');
  }

  String _generateTemplate() {
    final headers = widget.columns.map((col) => col.field).toList();
    final csvLines = <String>[];
    
    // Add headers
    csvLines.add(headers.join(','));
    
    // Add example data based on field names
    final exampleRow = headers.map((header) {
      switch (header.toLowerCase()) {
        case 'name':
          return 'Example Name';
        case 'email':
          return 'example@company.com';
        case 'phone':
          return '+1234567890';
        case 'amount':
          return '1000.00';
        case 'code':
          return 'EX001';
        case 'status':
          return 'ACTIVE';
        case 'due_date':
        case 'date':
          return '2025-01-01';
        case 'address':
        case 'location':
          return '123 Example Street';
        default:
          return 'Example Value';
      }
    }).map((value) => '"$value"').join(',');
    
    csvLines.add(exampleRow);
    
    return csvLines.join('\n');
  }

  void _showCreateDialog() {
    if (widget.buildCreateForm != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Add New ${widget.title.replaceAll('s', '')}'),
          content: SizedBox(
            width: 500,
            child: widget.buildCreateForm!({}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ).then((_) => _loadData());
    } else if (widget.createFormFields != null) {
      _showFormDialog(isEdit: false);
    }
  }

  void _showEditDialog(Map<String, dynamic> item) {
    if (widget.buildEditForm != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Edit ${widget.title.replaceAll('s', '')}'),
          content: SizedBox(
            width: 500,
            child: widget.buildEditForm!(item),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ).then((_) => _loadData());
    } else if (widget.editFormFields != null || widget.createFormFields != null) {
      _showFormDialog(isEdit: true, initialData: item);
    }
  }

  void _showFormDialog({bool isEdit = false, Map<String, dynamic>? initialData}) {
    final formFields = isEdit ? (widget.editFormFields ?? widget.createFormFields!) : widget.createFormFields!;
    final formKey = GlobalKey<FormState>();
    final formData = Map<String, dynamic>.from(initialData ?? {});

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isEdit ? 'Edit' : 'Add New'} ${widget.title.replaceAll('s', '')}'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: formFields.map((field) => _buildFormField(field, formData, formKey)).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final processedData = isEdit
                      ? (widget.onUpdateItem != null ? await widget.onUpdateItem!(formData) : formData)
                      : (widget.onCreateItem != null ? await widget.onCreateItem!(formData) : formData);

                  if (isEdit) {
                    await Api.dio.put('${widget.endpoint}/${initialData!['id']}', data: processedData);
                  } else {
                    await Api.dio.post(widget.endpoint, data: processedData);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${isEdit ? 'Updated' : 'Created'} successfully')),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(AdminFormField field, Map<String, dynamic> formData, GlobalKey<FormState> formKey) {
    if (field.type == AdminFieldType.custom && field.customWidget != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: field.customWidget!(formKey, formData, (fieldName, value) {
          formData[fieldName] = value;
        }),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildStandardFormField(field, formData),
    );
  }

  Widget _buildStandardFormField(AdminFormField field, Map<String, dynamic> formData) {
    switch (field.type) {
      case AdminFieldType.dropdown:
        return DropdownButtonFormField<String>(
          value: formData[field.field]?.toString(),
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          items: field.dropdownOptions?.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          )).toList(),
          onChanged: field.enabled ? (value) => formData[field.field] = value : null,
          validator: field.required ? (value) => value?.isEmpty ?? true ? 'This field is required' : null : null,
        );

      case AdminFieldType.date:
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          readOnly: true,
          controller: TextEditingController(text: formData[field.field]?.toString() ?? ''),
          onTap: field.enabled ? () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              formData[field.field] = date.toIso8601String().substring(0, 10);
            }
          } : null,
          validator: field.required ? (value) => value?.isEmpty ?? true ? 'This field is required' : null : null,
        );

      case AdminFieldType.number:
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            hintText: field.hint,
          ),
          keyboardType: TextInputType.number,
          initialValue: formData[field.field]?.toString(),
          enabled: field.enabled,
          onChanged: (value) => formData[field.field] = value,
          validator: field.required ? (value) => value?.isEmpty ?? true ? 'This field is required' : null : null,
        );

      case AdminFieldType.email:
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            hintText: field.hint,
          ),
          keyboardType: TextInputType.emailAddress,
          initialValue: formData[field.field]?.toString(),
          enabled: field.enabled,
          onChanged: (value) => formData[field.field] = value,
          validator: (value) {
            if (field.required && (value?.isEmpty ?? true)) {
              return 'This field is required';
            }
            if (value?.isNotEmpty ?? false) {
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                return 'Enter a valid email';
              }
            }
            return null;
          },
        );

      default: // text, password
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            hintText: field.hint,
          ),
          obscureText: field.type == AdminFieldType.password,
          initialValue: formData[field.field]?.toString(),
          enabled: field.enabled,
          onChanged: (value) => formData[field.field] = value,
          validator: field.required ? (value) => value?.isEmpty ?? true ? 'This field is required' : null : null,
        );
    }
  }
}

class AdminColumn {
  final String field;
  final String title;
  final int flex;

  AdminColumn({
    required this.field,
    required this.title,
    this.flex = 1,
  });
}

enum AdminFieldType { text, number, email, password, date, dropdown, checkbox, custom }

class AdminFormField {
  final String field;
  final String label;
  final AdminFieldType type;
  final bool required;
  final List<String>? dropdownOptions;
  final Widget Function(GlobalKey<FormState>, Map<String, dynamic>, Function(String, dynamic))? customWidget;
  final String? hint;
  final bool enabled;

  AdminFormField({
    required this.field,
    required this.label,
    required this.type,
    this.required = false,
    this.dropdownOptions,
    this.customWidget,
    this.hint,
    this.enabled = true,
  });
}
