import 'package:crown_security/core/api.dart';
import 'package:flutter/material.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<dynamic>? _complaints;
  bool _loading = true;
  String? _error;
  final _formKey = GlobalKey<FormState>();
  final _complaintController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
      final response = await Api.dio.get('/complaints', queryParameters: {'siteId': siteId});
      setState(() {
        _complaints = response.data;
      });
    } catch (e) {
      _error = 'Failed to load complaints.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _addComplaint() async {
    if (_formKey.currentState!.validate()) {
      final description = _complaintController.text;
      try {
        final siteId = await Api.storage.read(key: 'site_id');
        if (siteId == null) {
          throw Exception('Site ID not found');
        }
        await Api.dio.post('/complaints', data: {
          'complaint_text': description,
          'site_id': siteId,
        });
        _complaintController.clear();
        if (!mounted) return;
        Navigator.of(context).pop(); // Close the dialog
        _loadComplaints(); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit complaint.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints & Suggestions'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddComplaintDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_complaints == null || _complaints!.isEmpty) {
      return const Center(child: Text('No complaints or suggestions.'));
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _complaints!.length,
        itemBuilder: (context, index) {
          final complaint = _complaints![index];
      return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
        title: Text(complaint['complaint_text'] ?? complaint['description'] ?? 'Complaint'),
        subtitle: Text('Status: ${complaint['status'] ?? 'Open'}'),
        trailing: Text((() {
          final v = complaint['createdAt'] ?? complaint['date'];
          if (v == null) return '';
          DateTime? d;
          if (v is String) d = DateTime.tryParse(v);
          if (v is DateTime) d = v;
          if (d == null) return v.toString();
          return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
        })()),
            ),
          );
        },
      ),
    );
  }

  void _showAddComplaintDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Complaint/Suggestion'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _complaintController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description.';
                }
                return null;
              },
              maxLines: 3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addComplaint,
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
