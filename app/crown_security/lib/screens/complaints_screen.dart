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
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      _complaints = [
        {
          'id': '1',
          'description': 'Guard at Gate 1 was late.',
          'status': 'Resolved',
          'date': '2025-08-20'
        },
        {
          'id': '2',
          'description': 'Suggestion: Install a new light at the back.',
          'status': 'Pending',
          'date': '2025-08-28'
        },
      ];
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
      // TODO: Implement API call to add complaint
      final description = _complaintController.text;
      print('Adding complaint: $description');
      _complaintController.clear();
      Navigator.of(context).pop(); // Close the dialog
      _loadComplaints(); // Refresh the list
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
              title: Text(complaint['description']),
              subtitle: Text('Status: ${complaint['status']}'),
              trailing: Text(complaint['date']),
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
