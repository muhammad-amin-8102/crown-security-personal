import 'package:flutter/material.dart';
import '../../core/api.dart';

class AdminDataTable extends StatefulWidget {
  final String title;
  final String endpoint;
  final List<AdminColumn> columns;
  final Map<String, dynamic> Function(Map<String, dynamic>) mapRowData;
  final Widget Function(Map<String, dynamic>)? buildCreateForm;
  final Widget Function(Map<String, dynamic>)? buildEditForm;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final String? searchField;

  const AdminDataTable({
    super.key,
    required this.title,
    required this.endpoint,
    required this.columns,
    required this.mapRowData,
    this.buildCreateForm,
    this.buildEditForm,
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.searchField,
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
              if (widget.canCreate && widget.buildCreateForm != null)
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

  void _showCreateDialog() {
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
  }

  void _showEditDialog(Map<String, dynamic> item) {
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
